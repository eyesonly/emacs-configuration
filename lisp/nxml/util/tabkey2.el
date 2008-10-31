;;; tabkey2.el --- Use second tab key pressed for what you want
;;
;; Author: Lennart Borgman (lennart O borgman A gmail O com)
;; Created: 2008-03-15T14:40:28+0100 Sat
(defconst tabkey2:version "1.15")
;; Last-Updated: 2008-03-21T12:40:56+0100 Fri
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   `appmenu', `cl', `ourcomments-util', `popcmp'.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; The tab key is in Emacs often used for indentation.  However if you
;; press the tab key a second time and Emacs tries to do indentation
;; again, then usually nothing exciting will happen.  Then why not use
;; second tab key in a row for something else?
;;
;; Commonly used completion functions in Emacs is often bound to
;; something corresponding to Alt-Tab.  Unfortunately this is unusable
;; if you have a window manager that have an apetite for it (like that
;; on MS Windows for example, and several on GNU/Linux).
;;
;; Then using the second tab key press for what is bound to Alt-Tab
;; might be a good choice and perhaps also easy to remember.
;;
;; This little library tries to make it easy to do use the second tab
;; press for that.  See `tabkey2-mode' for more information.
;;
;;
;; This is a generalization of an idea Sebastien Rocca Serra once
;; presented on Emacs Wiki and called "Smart Tab".  (It seems like
;; many others have also using Tab for completion in one way or
;; another for years.)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change log:
;;
;; Version 1.04:
;; - Add overlay to display state after first tab.
;;
;; Version 1.05:
;; - Fix remove overlay problem.
;;
;; Version 1.06:
;; - Add completion function choice.
;; - Add support for popcmp popup completion.
;;
;; Version 1.07:
;; - Add informational message after first tab.
;;
;; Version 1.08:
;; - Give better informational message after first tab.
;;
;; Version 1.09:
;; - Put flyspell first.
;;
;; Version 1.09:
;; - Give the overlay higher priority.
;;
;; Version 1.10:
;; - Correct tabkey2-completion-functions.
;; - Add double-tab for modes where tab can not be typed again.
;; - Use better condition for when completion can be done, so that it
;;   can be done later while still on the same line.
;; - Add a better message handling for the "Tab completion state".
;; - Add C-g break out of the "Tab completion state".
;; - Add faces for highlight.
;; - Make it work in custom mode buffers.
;; - Fix documentation for `tabkey2-first'
;;
;; Version 1.11:
;; - Don't call chosen completion function directly.  Instead make it
;;   default for current buffer.
;;
;; Version 1.12:
;; - Simplify code.
;; - Add help to C-f1 during "Tab completion state".
;; - Fix documentation basics.
;; - Add customization of state message and line marking.
;; - Fix handling of double-Tab modes.
;; - Make user interaction better.
;; - Handle read-only in custom buffers better.
;; - Add more flexible check for if completion function is active.
;; - Support predictive mode.
;; - Reorder and simplify.
;;
;; Version 1.13:
;; - Add org-mode to the double-tab gang.
;; - Make it possible to use double-tab in normal buffers.
;; - Add cycling through completion functions to S-tab.
;;
;; Version 1.14:
;; - Fix bug in handling of read-only.
;; - Show completion binding in help message.
;; - Add binding to make current choice buffer local when cycling.
;;
;; Version 1.15:
;; - Fix problem at buffer end.
;; - Add S-tab to enter completion state without indentation.
;; - Add backtab bindings too for this.
;; - Remove double-tab, S-tab is better.
;; - Add list of modes that uses more tabs.
;; - Add list of modes that uses tab only for completion.
;; - Move first overlay when indentation changes.
;; - Make mark at line beginning 1 char long.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'popcmp nil t)
(require 'appmenu nil t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Custom

(defgroup tabkey2 nil
  "Customization of second tab key press."
  :group 'nxhtml
  :group 'convenience)

(defface tabkey2-highlight
  '((t :inherit highlight))
  "Face used to show that tab action 2 is on tab key."
  :group 'tabkey2)

;;(setq tabkey2-show-message 1)
(defcustom tabkey2-show-message 1
  "Show Tab completion state message if non-nil."
  :type '(radio
          (const :tag "Always" t)
          (const :tag "First time on row only" 1)
          (const :tag "Never" nil))
  :group 'tabkey2)

(defcustom tabkey2-show-mark-on-active-line t
  "Show mark on active line if non-nil."
  :type 'boolean
  :group 'tabkey2)

(defcustom tabkey2-in-minibuffer nil
  "If non-nil use command `tabkey2-mode' also in minibuffer."
  :type 'boolean
  :group 'tabkey2)

(defcustom tabkey2-in-appmenu t
  "Show a completion menu in command `appmenu-mode' if t."
  :type 'boolean
  :set (lambda (sym val)
         (set-default sym val)
         (when (featurep 'appmenu)
           (if val
               (appmenu-add 'tabkey2 nil t "Completion" 'tabkey2-appmenu)
             (appmenu-remove 'tabkey2))))
  :group 'tabkey2)

(defcustom tabkey2-completion-functions
  '(
    ("Spell check word" flyspell-correct-word-before-point)
    ("Predictive word" complete-word-at-point predictive-mode)
    ("XML completion" nxml-complete)
    ("Complete Emacs symbol" lisp-complete-symbol)
    ("Comint Dynamic Complete" comint-dynamic-complete)
    ("PHP completion" php-complete-function)
    ("Tags completion" complete-symbol)
    ("Dynamic word expansion" dabbrev-expand)
    ("Ispell complete word" ispell-complete-word)
    )
  "List of completion functions.
These are used by `tabkey2-choose-completion-function' in the
order they are found here.

The first 'active' entry in this list is normally used during the
'Tab completion state'.  An entry in the list is considered
active if:

-  The symbol is bound to a function

and

- it has a key binding at point,

  or

  the elisp expression evaluates to non-nil.
  If it is a single symbol then its variable value is used,
  otherwise the elisp form is evaled."
  :type '(repeat (list string (choice (command :tag "Currently know command")
                                      (symbol  :tag "Command not known yet"))
                       (sexp :tag "Elisp, if evaluate to non-nil then active")))
  :group 'tabkey2)

(defcustom tabkey2-alternate-completion-key [f8]
  "Alternate completion key."
  :set (lambda (sym val)
         (when (boundp 'tabkey2-mode-emul-map)
           (define-key tabkey2-mode-emul-map
             tabkey2-alternate-completion-key nil)
           (define-key tabkey2-completion-state-emul-map
             tabkey2-alternate-completion-key nil)
           (define-key tabkey2-mode-emul-map val 'tabkey2-first)
           (define-key tabkey2-completion-state-emul-map val 'tabkey2-first)
           (when tabkey2-completion-state-mode
             (tabkey2-completion-state-mode -1)
             (tabkey2-completion-state-mode 1)))
         (set-default sym val))
  :type 'key-sequence
  :group 'tabkey2)

(defcustom tabkey2-modes-that-uses-more-tabs
  '(python-mode
    haskell-mode
    makefile-mode
    org-mode
    Custom-mode
    ;; other
    cmd-mode
    )
  "In those modes use must use S-Tab to start completion state.
In those modes pressing Tab several types may make sense so you
can not go into´'Tab completion state' just because one Tab has
been pressed.  Instead you use S-Tab to go into that state.
After that Tab does completion.

You can do use S-Tab in other modes too if you want too."
  :type '(repeat command)
  :group 'tabkey2)

(defcustom tabkey2-modes-that-just-completes
  ;; Fix-me: Sometimes S-tab does not work here, why?
  '(shell-mode)
  "Tab is only used for completion in these modes.
Therefore `tabkey2-first' just calls the function on Tab."
  :type '(repeat command)
  :group 'tabkey2)

;;(setq tabkey2-use-popup-menus nil)
(defcustom tabkey2-use-popup-menus (when (featurep 'popcmp) t)
  "Use pop menus if available."
  :type 'boolean
  :group 'tabkey2)

(defvar tabkey2-preferred nil
  "Preferred function for second tab key press.")
(make-variable-buffer-local 'tabkey2-preferred)
(put 'tabkey2-preferred 'permanent-local t)

(defvar tabkey2-fallback nil
  "Fallback function for second tab key press.")
(make-variable-buffer-local 'tabkey2-fallback)
(put 'tabkey2-fallback 'permanent-local t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; State

(defvar tabkey2-overlay nil
  "Show when tab key 2 action is to be done.")
(defvar tabkey2-keymap-overlay nil
  "Hold the keymap for tab key 2.")
(defvar tabkey2-beg-mark nil)
(defvar tabkey2-end-mark nil)

;; (setq tabkey2-keymap-overlay nil)
(defconst tabkey2-completion-state-emul-map
  (let ((map (make-sparse-keymap)))
    (define-key map [tab]                 'tabkey2-complete)
    (define-key map [(shift tab)]         'tabkey2-cycle-through-completion-functions)
    (define-key map [backtab]             'tabkey2-cycle-through-completion-functions)
    (define-key map [(control shift tab)] 'tabkey2-choose-completion-function)
    (define-key map [(control backtab)]   'tabkey2-choose-completion-function)
    (define-key map [(control ?g)]        'tabkey2-completion-state-mode-turn-off)
    (define-key map [(control f1)]        'tabkey2-completion-state-help)
    (define-key map [(control ?c) tab]    'tabkey2-make-current-sticky)
    (define-key map tabkey2-alternate-completion-key 'tabkey2-complete)
    map)
  "This keymap is for `tabkey2-keymap-overlay'.")

(defun tabkey2-completion-state-p ()
  "Return t if Tab completion state should continue.
Otherwise return nil."
  (and (or (eobp)
           (eq (key-binding [tab]) 'tabkey2-complete))
       (= (line-beginning-position)
          (overlay-start tabkey2-keymap-overlay))))

(defun tabkey2-current-tab-info nil
  "Saved information message for Tab completion state.")
(defun tabkey2-current-tab-function nil
  "Tab completion state current completion function.")

(defun tabkey2-read-only-p ()
  "Return non-nil if buffer seems to be read-only at point."
  (or buffer-read-only
      (get-char-property (min (1+ (point)) (point-max)) 'read-only)
      (let ((remap (command-remapping 'self-insert-command (point))))
        (memq remap '(Custom-no-edit)))))

;;;; Minor mode active after first tab

(defun tabkey2-move-overlays ()
  ;; The marking overlay
  (let* ((beg (let ((inhibit-field-text-motion t))
                (line-beginning-position)))
         (ind (current-indentation))
         (end (+ beg 1)) ;(if (> ind 0) ind 1)))
         (inhibit-read-only t))
    ;;(message "beg=%s, end=%s" beg end) (sit-for 2)
    (unless tabkey2-overlay
      (setq tabkey2-overlay (make-overlay beg end)))
    ;; Fix-me: gets some strange errors, try avoid moving:
    (unless (and (eq (current-buffer) (overlay-buffer tabkey2-overlay))
                 (= beg (overlay-start tabkey2-overlay))
                 (= end (overlay-end   tabkey2-overlay)))
      (move-overlay tabkey2-overlay beg end (current-buffer)))
    ;; Give it a high priority, it is very temporary
    (overlay-put tabkey2-overlay 'priority 1000)
    (if tabkey2-show-mark-on-active-line
        (overlay-put tabkey2-overlay 'face 'tabkey2-highlight)
      (overlay-put tabkey2-overlay 'face nil)))
  ;; The keymap overlay
  (let ((beg (line-beginning-position))
        (end (line-end-position)))
    (setq tabkey2-beg-mark (copy-marker beg nil))
    (setq tabkey2-end-mark (copy-marker (1+ end) t)))
  (assert (or (eobp)
              (= tabkey2-beg-mark
                 (save-excursion
                   (goto-char (1- tabkey2-end-mark))
                   (line-beginning-position)))))
  ;;(setq tabkey2-keymap-overlay nil)
  (unless tabkey2-keymap-overlay
    (setq tabkey2-keymap-overlay (make-overlay 1 1))
    (overlay-put tabkey2-keymap-overlay 'priority 1000)
    (overlay-put tabkey2-keymap-overlay 'keymap
                 tabkey2-completion-state-emul-map))
  (move-overlay tabkey2-keymap-overlay tabkey2-beg-mark tabkey2-end-mark (current-buffer)))

(defvar tabkey2-completion-state-mode nil)
(defun tabkey2-completion-state-mode (arg)
  "Tab completion state minor mode.
This pseudo-minor mode holds the 'Tab completion state'.  When this
minor mode is on completion key bindings are available.

With ARG a positive number turn on, otherwise turn off this minor
mode.

See `tabkey2-first' for more information."
  (unless (assoc 'tabkey2-completion-state-mode minor-mode-alist)
    (setq minor-mode-alist (cons '(tabkey2-completion-state-mode " Tab2")
                                 minor-mode-alist)))
  (setq tabkey2-completion-state-mode (when (and (numberp arg)
                                                 (> arg 0))
                                        t))
  (if tabkey2-completion-state-mode
      (progn
        ;; Move overlays
        (tabkey2-move-overlays)
        ;; Set up for post-command-hook
        (add-hook 'post-command-hook 'tabkey2-post-command)
        (setq tabkey2-message-countdown tabkey2-show-message))
    (let ((inhibit-read-only t))
      (when tabkey2-keymap-overlay
        (delete-overlay tabkey2-keymap-overlay))
      (when tabkey2-overlay
        (delete-overlay tabkey2-overlay)))
    (remove-hook 'post-command-hook 'tabkey2-post-command)
    (message "")))

(defun tabkey2-completion-state-mode-turn-off ()
  "Quit Tab completion state."
  (interactive)
  (tabkey2-completion-state-mode -1)
  (message "Quit"))

(defvar tabkey2-is-cycling nil)

(defun tabkey2-post-command ()
  "Turn off Tab completion state if not feasable any more.
This is run in `post-command-hook' after each command."
  (condition-case err
      (save-match-data
        (unless (or (eq this-command 'tabkey2)
                    (= 0 (length (this-command-keys-vector)))
                    (active-minibuffer-window))
          (if (not (tabkey2-completion-state-p))
              (tabkey2-completion-state-mode -1)
            (tabkey2-move-overlays)
            (when (eq tabkey2-is-cycling 'tentative) (setq tabkey2-is-cycling nil))
            (when (and tabkey2-message-countdown
                       (not tabkey2-is-cycling))
              (when (integerp tabkey2-message-countdown)
                (setq tabkey2-message-countdown (1- tabkey2-message-countdown))
                (when (> 0 tabkey2-message-countdown)
                  (setq tabkey2-message-countdown nil))
                (when tabkey2-message-countdown
                  (unless (active-minibuffer-window)
                    (if (current-message)
                        (message "%s - %s"
                                 tabkey2-current-tab-info
                                 (current-message))
                      (message "%s" tabkey2-current-tab-info))))))
            (when tabkey2-is-cycling (setq tabkey2-is-cycling 'tentative))
            )))
    (error (message "tabkey2: %s" (error-message-string err)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Completion function selection etc

(defun tabkey2-is-active (fun chk)
  "Return t FUN is active.
Return t if CHK is a symbol with non-nil value or a form that
evals to non-nil.

Otherwise return t if FUN has a key binding at point."
  (or (if (symbolp chk)
          (when (boundp chk) (symbol-value chk))
        (eval chk))
      (let ((keys (tabkey2-symbol-keys fun))
            kb-bound)
        (dolist (key keys)
          (unless (memq (car (append key nil))
                        '(menu-bar))
            (setq kb-bound t)))
        kb-bound)))

(defun tabkey2-is-active-p (fun)
  "Return FUN is active.
Look it up in `tabkey2-completion-functions' to find out what to
check and return the value from `tabkey2-is-active'."
  (let ((chk (catch 'chk
               (dolist (rec tabkey2-completion-functions)
                 (when (eq fun (nth 1 rec))
                   (throw 'chk (nth 2 rec)))))))
    (tabkey2-is-active fun chk)))

(defun tabkey2-get-active-completion-functions ()
  "Get a list of active completion functions.
Consider only those in `tabkey2-completion-functions'."
  (delq nil
        (mapcar (lambda (rec)
                  (let ((fun (nth 1 rec))
                        (chk (nth 2 rec)))
                    (when (tabkey2-is-active fun chk) rec)))
                tabkey2-completion-functions)))

(defvar tabkey2-chosen-completion-function nil)
(make-variable-buffer-local 'tabkey2-chosen-completion-function)
(put 'tabkey2-chosen-completion-function 'permanent-local t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Handling of Tab key

(defun tabkey2-first (prefix)
  "Do something else after first Tab.
The Tab key is easy to type on your keyboard.  Then why not use
it for completion, something that is very useful?  This was the
idea of Smart Tabs and this is a generalization of that idea.

In Emacs the Tab key is usually used for indentation.  The idea
here is that if indentation has been done once since you entered
a line, then as long as point is on the same line further Tab
keys can do completion.

So you kind of do Tab-Tab for first completion and then just Tab
for further completions on the same line.

But of course, there must be some way to easily determine what
kind of completion because there are many in Emacs.

This function is bound to the Tab key when minor mode command
`tabkey2-mode' is on.  It works like this:

1. The first time Tab is pressed do whatever Tab would have done
   if minor mode command `tabkey2-mode' was off.

   Then enter a new temporary 'Tab completion state' for just the
   next command.  Show this by a highlight on the indentation and
   a marker \"Tab2\" in the mode line.

   However if either
     - the minibuffer is active and `tabkey2-in-minibuffer' is nil
     - `major-mode' is in `tabkey2-modes-that-uses-more-tabs'
   then do not enter this temporary 'Tab completion state'.

   For major modes where it make sense to press Tab several times
   S-Tab \(or backtab) can often be used to enter 'Tab completion
   state'.


2. As long as point is on the same line do completion when Tab is
   pressed again.  Show that this state is active with a
   highlighting at the line beginning, a marker on the mode
   line (Tab2) and a message in the echo area which tells what
   kind of completion will be done.

   When deciding what kind of completion to do look in the table
   below and do whatever it found first that is not nil:

   - `tabkey2-preferred'
   - `tabkey2-completion-functions'
   - `tabkey2-fallback'

   If C-f1 is pressed show help for current completion function.

3. If the default kind of completion is not what you want then
   you can choose completion function from any of the candidates
   in `tabkey2-completion-functions'.  During the 'Tab completion
   state' the following extra key bindings are available:

\\{tabkey2-completion-state-emul-map}

If used with a PREFIX argument \(like \\[universal-argument])
then just show what Tab will do.

-----
NOTE: This uses `emulation-mode-map-alists' and it supposes that
nothing else is bound to Tab there."
  (interactive "P")
  (if (and tabkey2-keymap-overlay
           (eq (overlay-buffer tabkey2-keymap-overlay) (current-buffer))
           (>= (point) (overlay-start tabkey2-keymap-overlay))
           (<= (point) (overlay-end   tabkey2-keymap-overlay)))
      ;; We should maybe not be here, but the keymap does not work at
      ;; the end of the buffer so we call the second tab function from
      ;; here:
      (if (memq 'shift (event-modifiers last-input-event))
          (call-interactively 'tabkey2-cycle-through-completion-functions)
        (call-interactively 'tabkey2-complete prefix))
    (let* ((emma-without-tabkey2
            ;; Remove keymaps from tabkey2 in this copy:
            (delq 'tabkey2--emul-keymap-alist
                  (copy-sequence emulation-mode-map-alists)))
           (just-completes (memq major-mode tabkey2-modes-that-just-completes))
           (what (if just-completes
                     'complete
                   (if (or (unless tabkey2-in-minibuffer
                             (active-minibuffer-window))
                           (use-region-p)
                           (memq major-mode tabkey2-modes-that-uses-more-tabs))
                       'indent
                     'indent-complete
                     )))
           (to-do-1 (unless (or (memq 'shift (event-modifiers last-input-event))
                                ;; Just turn on the completion mode then
                                (eq what 'complete))
                      (let ((emulation-mode-map-alists emma-without-tabkey2))
                        (key-binding [?\t] t))))
           (to-do-2 (unless (eq what 'indent)
                      (let ((emulation-mode-map-alists emma-without-tabkey2))
                        (or (when (and tabkey2-chosen-completion-function
                                       (tabkey2-is-active-p
                                        tabkey2-chosen-completion-function))
                              tabkey2-chosen-completion-function)
                            tabkey2-preferred
                            (tabkey2-first-active-from-completion-functions)
                            tabkey2-fallback)))))
      (if prefix
          (if (memq 'shift (event-modifiers last-input-event))
              (message "(TabKey2) Shift tab: turn on 'Tab completion state'")
            (message "(TabKey2) First tab: %s, next: maybe %s"
                     to-do-1 to-do-2))
        (when to-do-1
          (let ((last-command to-do-1)
                mumamo-multi-major-mode)
            (call-interactively to-do-1)))
        (unless (tabkey2-read-only-p)
          (when to-do-2
            (tabkey2-make-message-and-set-fun to-do-2)
            (tabkey2-completion-state-mode 1)
            (when just-completes (call-interactively 'tabkey2-complete))
            ))))))

(defun tabkey2-complete (prefix)
  "Call current completion function.
If used with a PREFIX argument then just show what Tab will do."
  (interactive "P")
  (if prefix
      (message "(TabKey2) Tab: %s" tabkey2-current-tab-function)
    (call-interactively tabkey2-current-tab-function)))

;; Use emulation mode map for first Tab key
(defconst tabkey2-mode-emul-map
  (let ((map (make-sparse-keymap)))
    (define-key map [tab] 'tabkey2-first)
    (define-key map tabkey2-alternate-completion-key 'tabkey2-first)
    map)
  "This keymap just binds tab all the time.")

(defconst tabkey2--emul-keymap-alist nil)

(define-minor-mode tabkey2-mode
  "More fun with Tab key number two (completion etc).
This minor mode binds Tab in a way that let you do completion
with Tab in all buffers \(where it is possible).  See
`tabkey2-first' for more information."
  :keymap nil
  :global t
  :group 'tabkey2
  (if tabkey2-mode
      (progn
        ;; Update emul here if keymap have changed
        (setq tabkey2--emul-keymap-alist
              (list (cons 'tabkey2-mode
                          tabkey2-mode-emul-map)))
        (add-to-list 'emulation-mode-map-alists 'tabkey2--emul-keymap-alist))
    (tabkey2-completion-state-mode -1)
    (setq emulation-mode-map-alists (delq 'tabkey2--emul-keymap-alist
                                          emulation-mode-map-alists))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; User interaction

(defun tabkey2-completion-state-help ()
  "Show help for current completion function."
  (interactive)
  (describe-function tabkey2-current-tab-function))

(defun tabkey2-get-key-binding (fun)
  "Get key binding for FUN during 'Tab completion state'."
  (let* ((remapped (command-remapping fun))
         (key (where-is-internal fun
                                 tabkey2-completion-state-emul-map
                                 t
                                 nil
                                 remapped)))
    key))

(defun tabkey2-make-message-and-set-fun (comp-fun)
  "Set current completion function to COMP-FUN.
Build message but don't show it."
  (setq tabkey2-current-tab-function comp-fun)
  (let* (
         ;;(chs-fun 'tabkey2-choose-completion-function)
         (chs-fun 'tabkey2-cycle-through-completion-functions)
         (key (tabkey2-get-key-binding chs-fun))
         (active-funs (tabkey2-get-active-completion-functions))
         what)
    (dolist (rec tabkey2-completion-functions)
      (let ((fun (nth 1 rec))
            (txt (nth 0 rec)))
        (when (eq fun comp-fun) (setq what txt))))
    (let ((info (concat (format "Next tab: %s" what)
                        (if (cdr (tabkey2-get-active-completion-functions))
                            (format ", other %s" (key-description key))
                          (", only one active")))))
      (setq tabkey2-current-tab-info
            (propertize info 'face 'tabkey2-highlight)))))

(defun tabkey2-get-active-string (bnd fun buf)
  "Get string to show for state.
BND: means active
FUN: function
BUF: buffer"
  (if bnd
      (if (with-current-buffer buf (tabkey2-read-only-p))
          (propertize "active, but read-only" 'face '( :foreground "red"))
        (propertize "active" 'face '( :foreground "green")))
    (if (fboundp fun)
        (propertize "not active" 'face '( :foreground "red"))
      (propertize "not defined" 'face '( :foreground "gray")))))

(defun tabkey2-show-completion-usage ()
  "Show what currently may be used for completion."
  (interactive)
  (let ((orig-buf (current-buffer))
        (orig-mn  mode-name)
        (active-mark (concat " " (propertize " <= " 'face '( :background "yellow"))))
        (act-found nil)
        (chosen-fun tabkey2-chosen-completion-function)
        what
        chosen)
    (when chosen-fun
      (dolist (rec tabkey2-completion-functions)
        (let ((fun (nth 1 rec))
              (txt (nth 0 rec)))
          (when (eq fun chosen-fun) (setq what txt))))
      (setq chosen (list what chosen-fun)))
    (with-output-to-temp-buffer (help-buffer)
      (help-setup-xref (list #'tabkey2-show-completion-usage) (interactive-p))
      (with-current-buffer (help-buffer)
        (insert "The completion functions available for 'Tab completion' in buffer\n'"
                (buffer-name orig-buf)
                "' at point with mode " orig-mn " are shown below.\n"
                "The first active function is used.\n\n")
        (if (not chosen)
            (insert "  None is chosen")
          (let* ((txt (nth 0 chosen))
                 (fun (nth 1 chosen))
                 (chk (nth 2 chosen))
                 (bnd (with-current-buffer orig-buf
                        (tabkey2-is-active fun chk)))
                 (act (tabkey2-get-active-string bnd fun orig-buf)))
            (insert (format "  Chosen currently is %s (%s): %s"
                            txt fun act))
            (when bnd (insert active-mark) (setq act-found t))))
        (insert "\n\n")
        (if (not tabkey2-preferred)
            (insert "  None is preferred")
          (let* ((txt (nth 0 tabkey2-preferred))
                 (fun (nth 1 tabkey2-preferred))
                 (chk (nth 2 chosen))
                 (bnd (with-current-buffer orig-buf
                        (tabkey2-is-active fun chk)))
                 (act (tabkey2-get-active-string bnd fun orig-buf)))
            (insert (format "  Preferred is %s (`%s')': %s"
                            txt fun act))
            (when bnd (insert active-mark) (setq act-found t))))
        (insert "\n\n")
        (dolist (comp-fun tabkey2-completion-functions)
          (let* ((txt (nth 0 comp-fun))
                 (fun (nth 1 comp-fun))
                 (chk (nth 2 comp-fun))
                 (bnd (with-current-buffer orig-buf
                        (tabkey2-is-active fun chk)))
                 (act (tabkey2-get-active-string bnd fun orig-buf)))
            (insert
             (format
              "  %s (`%s'): %s"
              txt fun act))
            (when (and (not act-found) bnd)
              (insert active-mark) (setq act-found t))
            (insert "\n")))
        (insert "\n")
        (if (not tabkey2-fallback)
            (insert "  There is no fallback")
          (let* ((txt (nth 0 tabkey2-fallback))
                 (fun (nth 1 tabkey2-fallback))
                 (chk (nth 2 tabkey2-fallback))
                 (bnd (with-current-buffer orig-buf
                        (tabkey2-is-active fun chk)))
                 (act (tabkey2-get-active-string bnd fun orig-buf)))
            (insert (format "  Fallback is %s (`%s'): %s"
                            txt fun act))
            (when (and (not act-found) bnd) (insert active-mark) (setq act-found t))))
        (insert "\n\nSee function `tabkey2-mode' for more information.")
        (print-help-return-message)))))

(defun tabkey2-first-active-from-completion-functions ()
  "Return first active completion function.
Look in `tabkey2-completion-functions' for the first function
that has an active key binding."
  (catch 'active-fun
    (dolist (rec tabkey2-completion-functions)
      (let ((fun (nth 1 rec))
            (chk (nth 2 rec)))
        (when (tabkey2-is-active fun chk)
          (throw 'active-fun fun))))))

(defvar tabkey2-completing-read 'completing-read)

(defun tabkey2-symbol-keys (comp-fun)
  "Get a list of all key bindings for COMP-FUN."
  (let* ((remapped (command-remapping comp-fun)))
    (where-is-internal comp-fun
                       nil ;;overriding-local-map
                       nil nil remapped)))

(defun tabkey2-set-fun (fun)
  "Use function FUN for next Tab in 'Tab completion state'."
  (setq tabkey2-chosen-completion-function fun)
  (unless fun
    (setq fun (tabkey2-first-active-from-completion-functions)))
  (tabkey2-make-message-and-set-fun fun)
  (when (tabkey2-completion-state-p)
    (message "%s" tabkey2-current-tab-info)))

(defun tabkey2-appmenu ()
  "Make a menu for minor mode command `appmenu-mode'."
  (unless (tabkey2-read-only-p)
    (let* ((cf-r (reverse (tabkey2-get-active-completion-functions)))
           (tit "Complete")
           (map (make-sparse-keymap tit)))
      (define-key map [tabkey2-usage]
        (list 'menu-item "Show available completion functions info"
              'tabkey2-show-completion-usage))
      (define-key map [tabkey2-divider-1] (list 'menu-item "--"))
      (let ((set-map (make-sparse-keymap "Set completion")))
        (define-key map [tabkey2-choose]
          (list 'menu-item "Set Tab completion for buffer" set-map))
        (dolist (cf-rec cf-r)
          (let ((dsc (nth 0 cf-rec))
                (fun (nth 1 cf-rec)))
            (define-key set-map
              (vector (intern (format "tabkey2-set-%s" fun)))
              (list 'menu-item dsc
                    `(lambda ()
                       (interactive)
                       (tabkey2-set-fun ',fun))
                    :button
                    `(:radio
                      . (eq ',fun tabkey2-chosen-completion-function))))))
        (define-key set-map [tabkey2-set-div] (list 'menu-item "--"))
        (define-key set-map [tabkey2-set-default]
          (list 'menu-item "Default Tab completion"
                (lambda ()
                  (interactive)
                  (tabkey2-set-fun nil))
                :button
                '(:radio . (null tabkey2-chosen-completion-function))))
        (define-key set-map [tabkey2-set-header-div] (list 'menu-item "--"))
        (define-key set-map [tabkey2-set-header]
          (list 'menu-item "Set Tab completion for buffer"))
        )
      (define-key map [tabkey2-divider] (list 'menu-item "--"))
      (dolist (cf-rec cf-r)
        (let ((dsc (nth 0 cf-rec))
              (fun (nth 1 cf-rec)))
          (define-key map
            (vector (intern (format "tabkey2-call-%s" fun)))
            (list 'menu-item dsc fun
                  :button
                  `(:toggle
                    . (eq ',fun tabkey2-chosen-completion-function))
                  ))))
      map)))

(defun tabkey2-completion-menu-popup ()
  "Pop up a menu with completion alternatives."
  (interactive)
  (let ((menu (tabkey2-appmenu)))
    (popup-menu-at-point menu)))

(defun tabkey2-add-to-appmenu ()
  "Add a menu to function `appmenu-mode'."
  (appmenu-add 'tabkey2 nil t "Completion" 'tabkey2-appmenu))

(defun tabkey2-choose-completion-function ()
  "Set current completion function.
Let user choose completion function from those in
`tabkey2-completion-functions' that have some key binding at
point.

Let the chosen completion function be the default for subsequent
completions in the current buffer."
  ;; Fix-me: adjust to mumamo.
  (interactive)
  (save-match-data
    (if (and (featurep 'popcmp)
             tabkey2-use-popup-menus)
        (tabkey2-completion-menu-popup)
      (when (eq 'completing-read tabkey2-completing-read) (isearch-unread 'tab))
      (let* ((cf-r (reverse (tabkey2-get-active-completion-functions)))
             (cf (cons '("- Use default Tab completion" nil) cf-r))
             (hist (mapcar (lambda (rec)
                             (car rec))
                           cf))
             (tit (funcall tabkey2-completing-read "Set current completion function: " cf
                           nil ;; predicate
                           t   ;; require-match
                           nil ;; initial-input
                           'hist ;; hist
                           ))
             (fun-rec (assoc-string tit cf))
             (fun (cadr fun-rec)))
        (setq tabkey2-chosen-completion-function fun)
        (unless fun
          (setq fun (tabkey2-first-active-from-completion-functions)))
        (tabkey2-make-message-and-set-fun fun)
        (when (tabkey2-completion-state-p)
          (message "%s" tabkey2-current-tab-info))))))

(defun tabkey2-make-current-sticky ()
  "Make current Tab completion function sticky.
Set the current Tab completion function at point as default for
the current buffer."
  (interactive)
  (let ((set-it
         (y-or-n-p
          (format
           "Make %s default for Tab completion in current buffer? "
           tabkey2-current-tab-function))))
    (when set-it
      (setq tabkey2-chosen-completion-function
            tabkey2-current-tab-function))
    (unless set-it
      (when (local-variable-p 'tabkey2-chosen-completion-function)
        (when (y-or-n-p "Use default Tab completion selection in buffer? ")
          (setq set-it t))
        (kill-local-variable 'tabkey2-chosen-completion-function)))
    (when (tabkey2-completion-state-p)
      (message "%s%s" tabkey2-current-tab-info
               (if set-it " - Done" "")))))

(defun tabkey2-cycle-through-completion-functions (prefix)
  "Cycle through completion functions or show current.
If PREFIX is given just show what shift tab will do."
  (interactive "P")
  (save-match-data
    (if prefix
        (message "(TabKey2) Shift tab: show/cycle completion function")
      (when (or tabkey2-message-countdown
                tabkey2-is-cycling)
        ;; Message is shown currently so change
        (let* ((active (mapcar (lambda (rec)
                                 (nth 1 rec))
                               (tabkey2-get-active-completion-functions)))
               (first (car active))
               next)
          (when tabkey2-current-tab-function
            (while (and active (not next))
              (when (eq (car active) tabkey2-current-tab-function)
                (setq next (cadr active)))
              (setq active (cdr active))))
          (unless next (setq next first))
          (tabkey2-make-message-and-set-fun next)))
      (let* ((key (tabkey2-get-key-binding 'tabkey2-make-current-sticky))
             (how-sticky (format " - use %s to stick"
                                 (key-description key))))
        (message "%s %s" tabkey2-current-tab-info how-sticky))
      (setq tabkey2-is-cycling t))))


(provide 'tabkey2)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; tabkey2.el ends here
