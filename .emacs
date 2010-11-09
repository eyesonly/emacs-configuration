;;----------------------------------------------------------------------------
;; Are we an aquamacs emacs?
;;----------------------------------------------------------------------------
(defvar aquamacs-p (string-match "Aquamacs" (version)))

;;----------------------------------------------------------------------------
;; Cut and paste interaction (not for aquamacs)
;;----------------------------------------------------------------------------
;; (cond
;;  ((eq aquamacs-p 'nil)

;; ;; Cut and paste interaction
;; '' (setq x-select-enable-clipboard t) ; as above
;; '' (setq interprogram-paste-function 'x-cut-buffer-or-selection-value)
;; ;;  (setq x-select-enable-clipboard t) ; as above
;; ;;  (setq interprogram-paste-function 'x-cut-buffer-or-selection-value)
;; ;;  (menu-bar-enable-clipboard)
;; ;; turn off toolbar
;; (tool-bar-mode 0)
;;  )
;; )

;;----------------------------------------------------------------------------
;; Emacs 23: will need ruby elisp packages to be loaded
;; (Emacs 22 on Ubuntu doesn't need this as it gets it from path.el)
;;----------------------------------------------------------------------------
(if (string-match "23" (version))
(setq load-path (cons "~/lisp/ruby1.8-elisp" load-path) byte-compile-warnings nil))
;;(setq load-path (cons "~usr/share/emacs22/site-lisp/ruby1.8-elisp" load-path) byte-compile-warnings nil))

(set-language-environment "utf-8")

;;TODO automate path load state
;; loadpath; this will recursivel add all dirs in 'elisp-path' to load-path
;; (defconst elisp-path '("~/.emacs.d/elisp/")) ;; my elisp directories
;; (mapcar '(lambda(p)
;;            (add-to-list 'load-path p)
;;            (cd p) (normal-top-level-add-subdirs-to-load-path)) elisp-path)


;;----------------------------------------------------------------------------
;; run emacs as a server so that emacsclient can connect
;;----------------------------------------------------------------------------
(server-start)

;;----------------------------------------------------------------------------
;; post mode for mail editing under mutt
;;----------------------------------------------------------------------------
(load "~/lisp/post-2.4/post")
; (defadvice server-process-filter (after post-mode-message first activate)
;    "If the buffer is in post mode, overwrite the server-edit
;    message with a post-save-current-buffer-and-exit message."
;    (if (eq major-mode 'post-mode)
;        (message
;         (substitute-command-keys "Type \\[describe-mode] for help composing; \\[post-save-current-buffer-and-exit] when done."))))
;;; ; This is also needed to see the magic message.  Set to a higher
;;; ; number if you have a faster computer or read slower than me.

; (font-lock-verbose 1000)
 (setq server-temp-file-regexp "mutt-")
 (add-hook 'server-switch-hook
         (function (lambda()
                     (cond ((string-match "Post" mode-name)
                            (post-goto-body))))))
(add-to-list 'auto-mode-alist '("/mutt" . post-mode))

;; Customize post mode a bit.
(defun my-post-mode-hook ()
  ;Add a key binding for ispell-buffer.
  (local-set-key (kbd "C-c z") 'server-edit)
  (local-set-key (kbd "C-c y") 'ispell-message)
  (local-set-key (kbd "C-c x") 'ispell-buffer)
  (auto-fill-mode 't)
)
(add-hook 'post-mode-hook 'my-post-mode-hook)


;; "y or n" instead of "yes or no"
(fset 'yes-or-no-p 'y-or-n-p)

;; turn off toolbar/menu/scroll - non graphical
(if (equal (window-system) nil)
  (progn
    (if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
    (if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
    (if (fboundp 'menu-bar-mode) (menu-bar-mode -1))
    (defvar jjgnox "t")
    (global-set-key "\C-cs"  'help-command)
;;  (define-key global-map "\C-h" 'backward-delete-char)
  )
)

(if (string-match "GTK+" (version))
 (progn
  (tool-bar-mode 0)
  (defvar jjgnox "f")
 ))

;;----------------------------------------------------------------------------
;;   All of the code below from
;;   http://blog.katipo.co.nz/?p=38
;;----------------------------------------------------------------------------
;; Set up syntax highlighting (font-lock)
;;----------------------------------------------------------------------------

(cond ((fboundp 'global-font-lock-mode)
       ;; Turn on font-lock in all modes that support it
       (global-font-lock-mode t)
       ;; Maximum colors
       (setq font-lock-maximum-decoration t)))


(add-hook 'text-mode-hook
          (function
           (lambda ()
             (auto-fill-mode)
             )))

;; Set up frame position and coloring
;; (setq default-frame-alist
;;       '(
;;        (background-color . "black")
;;        (foreground-color . "green")
;;         ))

;;;
;; css mode
(setq cssm-indent-function 'cssm-c-style-indenter)

;;;
;; ruby mode
(autoload 'ruby-mode "ruby-mode" "Load ruby-mode")
(add-hook 'ruby-mode-hook 'turn-on-font-lock)

;; associate ruby-mode with .rb files and .rjs files
(add-to-list 'auto-mode-alist '(".rb$" . ruby-mode))
(add-to-list 'auto-mode-alist '(".rjs$" . ruby-mode))
(add-to-list 'auto-mode-alist '(".rake$" . ruby-mode))

(setq interpreter-mode-alist (append '(("ruby" . ruby-mode))
                                     interpreter-mode-alist))

;; Ruby-Interpreter:
(autoload 'run-ruby "inf-ruby"
  "Run an inferior Ruby process")
(autoload 'inf-ruby-keys "inf-ruby"
  "Set local key defs for inf-ruby in ruby-mode")
(add-hook 'ruby-mode-hook
          '(lambda ()
             (inf-ruby-keys)
             ))

;; If you get a failure loading ruby electric on Ubuntu, install the ruby-elisp pkg
 (require 'ruby-electric)
 (ruby-electric-mode t)

;;ruby block doesn't seem to do much C-M n to go forward a block in ruby.el is better?
;;ruby block
(add-to-list 'load-path "~/lisp/ruby-block")
(require 'ruby-block)
(add-hook 'ruby-mode-hook
          '(lambda ()
             (ruby-block-mode t)
             ))

;; do overlay
(setq ruby-block-highlight-toggle 'overlay)
;; display to minibuffer
(setq ruby-block-highlight-toggle 'minibuffer)
;; display to minibuffer and do overlay
(setq ruby-block-highlight-toggle t)

;;ruby-debug (from: http://pragmaticdevnotes.wordpress.com/2008/11/25/emacs-on-windows-ruby-ruby-on-rails/ )
(add-to-list 'load-path "~/lisp/rdebug")
(autoload 'rdebug "rdebug" "Ruby debugging support." t)
;; (global-set-key [f5] 'gud-step)
;; (global-set-key [f6] 'gud-next)
;; (global-set-key [f8] 'gud-cont)
(global-set-key "\C-c\C-u" 'rdebug)


;;{BEGIN Commented out for testing nxml mode
;; ;;;
;; ;; mmm mode for editing rhtml files
;; (add-to-list 'load-path "~/lisp/mmm-mode-0.4.8/share/emacs/site-lisp")
;; (require 'mmm-mode)
;; (require 'mmm-auto)
;; (setq mmm-global-mode 'maybe)
;; (setq mmm-submode-decoration-level 2)
;; ;; (set-face-background 'mmm-output-submode-face  "Black")
;; ;; (set-face-background 'mmm-code-submode-face    "Black")
;; ;; (set-face-background 'mmm-comment-submode-face "Black")
;; ;; (set-face-foreground 'mmm-output-submode-face "Green")
;; ;; (set-face-foreground 'mmm-code-submode-face "Green")
;; ;; (set-face-foreground 'mmm-comment-submode-face "Red")
;; (set-face-background 'mmm-output-submode-face  "Yellow")
;; (set-face-background 'mmm-code-submode-face    "Yellow")
;; (set-face-background 'mmm-comment-submode-face "Yellow")
;; (set-face-foreground 'mmm-output-submode-face "Black")
;; (set-face-foreground 'mmm-code-submode-face "Black")
;; (set-face-foreground 'mmm-comment-submode-face "Black")
;; (mmm-add-classes
;;  '((erb-code
;;     :submode ruby-mode
;;     :match-face (("<%#" . mmm-comment-submode-face)
;;                  ("<%=" . mmm-output-submode-face)
;;                  ("<%"  . mmm-code-submode-face))
;;     :front "<%[#=]?"
;;     :back "-?%>"
;;     :insert ((?% erb-code       nil @ "<%"  @ " " _ " " @ "%>" @)
;;              (?# erb-comment    nil @ "<%#" @ " " _ " " @ "%>" @)
;;              (?= erb-expression nil @ "<%=" @ " " _ " " @ "%>" @))
;;     )))
;; (add-hook 'html-mode-hook
;;           (lambda ()
;;             (setq mmm-classes '(erb-code))
;;             (mmm-mode-on)))
;; (global-set-key [f8] 'mmm-parse-buffer)
;;}END


;;----------------------------------------------------------------------------
;;perl mode
;;----------------------------------------------------------------------------
;; (add-hook 'perl-mode-hook
;;           (lambda ()
;;              (global-set-key [f1] 'cperl-perldoc-at-point)))
;;; cperl-mode is preferred to perl-mode
;;; "Brevity is the soul of wit" <foo at acm.org>
(defalias 'perl-mode 'cperl-mode)

;;----------------------------------------------------------------------------
;; nxml mode - as per platypope and nxml mode, except I use nxhtml mode
;;----------------------------------------------------------------------------
;; Setup to get sane flyspell everywhere
(require 'flyspell)

(setq flyspell-mouse-map
      (let ((map (make-sparse-keymap)))
        (define-key map [down-mouse-3] 'flyspell-correct-word)
        map))

;; for now (add-hook 'font-lock-mode-hook 'flyspell-prog-mode)
;;

   (load "~/lisp/nxml/autostart.el")
   (load "~/lisp/misc/xml-fragment.el")
(require 'xml-fragment)

(defvar nxml-mode-abbrev-table
  (let (table)
    (define-abbrev-table 'table ())
    table)
  "Abbrev table in use in ruby-mode buffers.")

(add-hook 'nxml-mode-hook 'llasram/nxml-set-abbrev-table)
(defun llasram/nxml-set-abbrev-table ()
  (setq local-abbrev-table nxml-mode-abbrev-table))

(add-hook 'nxml-mode-hook 'xml-fragment-mode-on-maybe)

;;jonathan - to investigate where flyspell-prog-text-faces comes from
(add-to-list 'flyspell-prog-text-faces 'nxml-text-face)

(defun nxml-fontify-mode ()
  (nxml-mode)
  (mmm-mode-on)
  (font-lock-fontify-buffer)
  (nxml-fontify-buffer))

;; Destroy!
(setq magic-mode-alist
      '(("%![^V]" . ps-mode)
        ("# xmcd " . conf-unix-mode)))

;; Key bindings
(add-hook 'nxml-mode-hook 'llasram/nxml-extra-keys)
(defun llasram/nxml-extra-keys ()
  (define-key nxml-mode-map "\M-h" 'backward-kill-word)
  (define-key nxml-mode-map "\C-m" 'newline-and-indent))

;;Print using web browser option: see http://www.emacswiki.org/emacs/PrintWithWebBrowser
(require 'hfyview)

;;----------------------------------------------------------------------------
;; end of nxml mode
;;----------------------------------------------------------------------------


;;(add-to-list 'auto-mode-alist '("\\.rhtml$" . html-mode))


;;extra additions for mmm mode from http://www.credmp.org/index.php/2006/11/28/ruby-on-rails-and-emacs/
;; (set-face-background 'mmm-output-submode-face  "LightGrey")
;; (set-face-background 'mmm-code-submode-face    "white")
;; (set-face-background 'mmm-comment-submode-face "lightgrey")

;; shortcut to reparse the buffer


;;;
 ;; yaml mode
 (autoload 'yaml-mode "yaml-mode" "YAML" t)
 (setq auto-mode-alist
       (append '(("\\.yml$" . yaml-mode)) auto-mode-alist))

;;;
 ;; rails mode
 (defun try-complete-abbrev (old)
   (if (expand-abbrev) t nil))

 (setq hippie-expand-try-functions-list
       '(try-complete-abbrev
         try-complete-file-name
         try-expand-dabbrev))

  (setq load-path (cons "~/lisp/snippet" load-path))
  (setq load-path (cons "~/lisp/emacs-rails-0.5.99.5" load-path))
  (setq load-path (cons "~/lisp/find-recursive" load-path))
  (require 'rails)
;;   (setq rails-use-mongrel t)

 ;; make #! scripts executable after saving them
 (add-hook 'after-save-hook 'executable-make-buffer-file-executable-if-script-p)

;;----------------------------------------------------------------------------
;; ECB and its dependancies - textmate-like sidebar
;;----------------------------------------------------------------------------

;; wordwrap when vertically seperated buffer
(setq truncate-partial-width-windows nil)

;; Load CEDET
;;(load-file "~/lisp/cedet-1.0pre4/common/cedet.el")

;; Commented out on Ubuntu 10.10 at the moment
;;(global-ede-mode 1)
;;(semantic-mode 1)


;; Enabling various SEMANTIC minor modes.  See semantic/INSTALL for more ideas.
;; Select one of the following:

;; * This enables the database and idle reparse engines
;;(semantic-load-enable-minimum-features)

;; * This enables some tools useful for coding, such as summary mode
;;   imenu support, and the semantic navigator
;;(semantic-load-enable-code-helpers)

;; * This enables even more coding tools such as the nascent intellisense mode
;;   decoration mode, and stickyfunc mode (plus regular code helpers)
;; (semantic-load-enable-guady-code-helpers)

;; * This turns on which-func support (Plus all other code helpers)
;; (semantic-load-enable-excessive-code-helpers)

;; This turns on modes that aid in grammar writing and semantic tool
;; development.  It does not enable any other features such as code
;; helpers above.
;; (semantic-load-enable-semantic-debugging-helpers)


;; (add-to-list 'load-path "~/lisp/ecb-2.32")
;; (require 'ecb-autoloads)

;;only want ECB if running graphically -non graphically want speedy start up

(cond
 ((string-match "f" jjgnox)

;; Commented out Ubuntu 10.10
;;  (add-to-list 'load-path "~/lisp/ecb-snap")
;;  (require 'ecb)

;; From: http://www.postsubmeta.net/MyConfig/Emacs
;; subversion support
  (require 'vc-svn)


  ))

;; (ecb-activate)
;;(ecb-deactivate)

;;From http://www.emacswiki.org/emacs/Git
;; (require 'vc-git)
;; (when (featurep 'vc-git) (add-to-list 'vc-handled-backends 'git))
;; ;;(require 'git)
;; (autoload 'git-blame-mode "git-blame"
;;            "Minor mode for incremental blame for Git." t)

;;from http://paste.lisp.org/display/65631
;; (defun ecb-vc-dir-managed-by-git (directory)
;;     (let* ((cannon (file-truename directory))
;;            (gitdir (concat cannon "/.git/")))
;;       (if (eq cannon "/")
;;           nil
;;         (cond ((and (ecb-file-exists-p gitdir)
;;                     (locate-library "vc-git"))
;;                'git)
;;               (t
;;                (ecb-vc-dir-managed-by-git (concat cannon "/../")))))))

;;----------------------------------------------------------------------------
;; NAV - looks like a lighter version of ECB that is maintained
;;----------------------------------------------------------------------------
(add-to-list 'load-path "~/lisp/nav34")
(require 'nav)
(global-set-key (kbd "C-c n") 'nav)
(global-set-key (kbd "C-c C-n") 'nav-quit)

;;----------------------------------------------------------------------------
;; delete this block soon
;;----------------------------------------------------------------------------
;;;----Think this is wrong: turn on rails mode after ecb, according to: http://sodonnell.wordpress.com/2007/07/03/emacs-and-rails/
;; (require 'snippet)
;; (require 'find-recursive)
;; (require 'rails)


;;----------------------------------------------------------------------------
;; to investigate when I have the time
;;----------------------------------------------------------------------------
;; tabs for buffers
;;(require 'tabbar)
;;(tabbar-mode)



;;----------------------------------------------------------------------------
;; From: http://wiki.rubyonrails.org/rails/pages/HowToUseEmacsWithRails
;;----------------------------------------------------------------------------

;;should pull in html mode
(autoload 'ruby-mode "ruby-mode" "Ruby editing mode." t)
(setq auto-mode-alist  (cons '("\\.rb$" . ruby-mode) auto-mode-alist))
(setq auto-mode-alist  (cons '("\\.rhtml$" . html-mode) auto-mode-alist))

(modify-coding-system-alist 'file "\\.rb$" 'utf-8)
(modify-coding-system-alist 'file "\\.rhtml$" 'utf-8)

;;still not sure of the value of the following:
;; (add-hook 'ruby-mode-hook
;;           (lambda()
;;             (add-hook 'local-write-file-hooks
;;                       '(lambda()
;;                          (save-excursion
;;                            (untabify (point-min) (point-max))
;;                            (delete-trailing-whitespace)
;;                            )))
;;             (set (make-local-variable 'indent-tabs-mode) 'nil)
;;             (set (make-local-variable 'tab-width) 2)
;;             (imenu-add-to-menubar "IMENU")
;;             (require 'ruby-electric)
;;             (ruby-electric-mode t)
;;             ))

;;----------------------------------------------------------------------------
;; ri docs
;;----------------------------------------------------------------------------
(setq ri-ruby-script "/home/jonathan/lisp/ri_docs/ri-emacs.rb")
(autoload 'ri "/home/jonathan/lisp/ri_docs/ri-ruby.el" nil t)

;; (autoload 'ri "ri-ruby.el" nil t)

;; RI everywhere!
(define-key help-map "r" 'ri)

;;keybinds - F1/F4/M-C-i
;; (add-hook 'ruby-mode-hook (lambda () (local-set-key (quote [f1]) (ri))
;;                           ))

;;   (add-hook 'ruby-mode-hook (lambda ()
;;                               (local-set-key 'f1 'ri)
;;                               (local-set-key "\M-\C-i" 'ri-ruby-complete-symbol)
;;                               (local-set-key 'f4 'ri-ruby-show-args)
;;                               ))

;;----------------------------------------------------------------------------
;; xmp as per Pragdave - Gotoken's xmp - C-c C-b
;; http://raa.ruby-lang.org/project/xmp
;;----------------------------------------------------------------------------
;; PragDave -- This li'l beaut runs Gotoken's xmp processor on a region.
;; This adds the results of evaluating each line to the end of that line.
 (defun ruby-xmp-region (reg-start reg-end)
     (interactive "r")
     (shell-command-on-region reg-start reg-end
              "ruby -r /usr/pkg/lib/ruby/1.8/irb/xmp.rb  -n -e 'xmp($_, \"%l\t\t# %r\n\")'" t))

;;----------------------------------------------------------------------------
;; xmpfilter as per platypope - mfp's xmpfilter - C-c C-a - not working under aquamacs
;; http://raa.ruby-lang.org/project/xmpfilter/
;;----------------------------------------------------------------------------
;; Pipe the current buffer through mfp's xmpfilter
(defun ruby-annotate-buffer ()
  "Send the current current buffer to the annotation filter."
  (interactive "*")
  (let ((initial-line (count-lines (point-min) (point)))
        (initial-char (- (point) (point-at-bol))))
    (shell-command-on-region (point-min) (point-max) "ruby ~/lisp/xmpfilter-0.3.0/xmpfilter.rb -a" nil t)
    (goto-line initial-line)
    (forward-char initial-char)))

;;----------------------------------------------------------------------------
;; Some ruby-specific key-bindings
;;----------------------------------------------------------------------------
(add-hook 'ruby-mode-hook 'jjg/ruby-extra-keys)
(defun jjg/ruby-extra-keys ()
;;   (define-key ruby-mode-map "\C-m"      'newline-and-indent)
;;   (define-key ruby-mode-map " "         'ruby-electric-space)
;;   (define-key ruby-mode-map [backspace] 'ruby-electric-backspace)
;;   (define-key ruby-mode-map "\C-h"      'ruby-electric-backspace)
;;   (define-key ruby-mode-map [delete]    'ruby-electric-delete)
;;   (define-key ruby-mode-map "\C-d"      'ruby-electric-delete)
  (define-key ruby-mode-map "\C-c\C-b"  'ruby-xmp-region)
  (define-key ruby-mode-map "\C-c\C-a"  'ruby-annotate-buffer))

;;----------------------------------------------------------------------------
;; PYTHON
;;----------------------------------------------------------------------------

;;pydb - thank you Rocky Bernstein!
(add-to-list 'load-path "~/lisp/pydb")
(autoload 'pydb "pydb" "Run the python debugger." t)


;;----------------------------------------------------------------------------
;; Jonathan specific
;;----------------------------------------------------------------------------
;; Jonathan's custom keybinds
;; (global-set-key [?\C-,] 'comment-region)
;; (global-set-key [?\C-.] 'uncomment-region)
(global-set-key (kbd "C-<") 'comment-region)
(global-set-key (kbd "C->") 'uncomment-region)
(global-set-key (kbd "C-c c") 'comment-region)
(global-set-key (kbd "C-c u") 'uncomment-region)
(global-set-key (kbd "C-c e") 'ecb-activate)
(global-set-key (kbd "C-c d") 'ecb-deactivate)
(global-set-key (kbd "C-c o") 'other-window)
(global-set-key (kbd "C-c r") 'revert-buffer)

;;(global-set-key (kbd "C-c ^") 'enlarge-ten)
;; (global-set-key (kbd "C-c b") 'iswitchb-buffer-other-window)
(global-set-key "\C-c^" '(lambda ()
                          (interactive)
                          (enlarge-window 10)
                          ))
;;kill ring popup
(global-set-key "\C-cw" '(lambda ()
                           (interactive)
                           (popup-menu 'yank-menu)))


;;I like to toggle autofill a lot replace (set-fill-column) with this binding
;; (global-set-key [?\C-x f] 'auto-fill-mode)
(global-set-key "\C-xf" 'auto-fill-mode)

;;all backup files go into my .emacs.d directory instead of littering filesystem
(defun make-backup-file-name (file)
(concat "~/.emacs.d/" (file-name-nondirectory file) "~"))

;;and instead of littering the filesystem with semantic.cache's
;; from: http://blog.ox.cx/2006/04/25/getting-rid-of-semanticcaches/
(setq semanticdb-default-save-directory "~/tmp/semantic.cache")

;; go to a specific column, useful in Macros
;; From: http://communitygrids.blogspot.com/2007/11/emacs-goto-column-function.html
(defun goto-column-number (number)
"Untabify, and go to a column number within the current line (1 is beginning
of the line)."
(interactive "nColumn number ( - 1 == C) ? ")
(beginning-of-line)
(untabify (point-min) (point-max))
(while (> number 1)
 (if (eolp)
     (insert ? )
   (forward-char))
 (setq number (1- number))))

(global-set-key (kbd "C-c C-c C-c") 'goto-column-number)

;;my own function to kill other buffer
(defun kill-other-buffer ()
  (interactive)
  (other-window 1)
  (kill-buffer (current-buffer))
  (other-window 1)
)
(global-set-key (kbd "C-c k") 'kill-other-buffer)

;;my own function to goto terminal
(defun goto-terminal ()
  (interactive)
  (switch-to-buffer-other-window "term-first")
 (other-window 1)               ;; move back to first window
 (balance-windows)
 (shrink-window 10)
)

;; (global-set-key (kbd "C-c t") 'goto-terminal)

;; from: http://www.dotfiles.com/files/6/466_dot-emacs
;;Enable iswitchb buffer mode. I find it easier to use than the
;;regular buffer switching. While we are messing with buffer
;;movement, the second sexp hides all the buffers beginning
;;with "*". The third and fourth sexp does some remapping.
;;My instinct is to go left-right in a completion buffer, not C-s/C-r
(iswitchb-mode 1)
(defun iswitchb-local-keys ()
  (mapc (lambda (K)
          (let* ((key (car K)) (fun (cdr K)))
            (define-key iswitchb-mode-map (edmacro-parse-keys key)
fun)))
        '(("<right>" . iswitchb-next-match)
          ("<left>"  . iswitchb-prev-match)
          ("<up>"    . ignore             )
          ("<down>"  . ignore             ))))
(add-hook 'iswitchb-define-mode-map-hook 'iswitchb-local-keys)

;;;;Completion ignores filenames ending in any string in this list.
(setq completion-ignored-extensions
      '(".o" ".elc" ".class" "java~" ".ps" ".abs" ".mx" ".~jv" ))

;;;;We can also get completion in the mini-buffer as well.
(icomplete-mode t)

;;from http://www.joegrossberg.com/archives/000182.html
;; gives list of recently opened files (only GNUemacs)
 (require 'recentf)
;; (setq recentf-auto-cleanup 'never) ;;To protect tramp
 (add-to-list 'recentf-keep 'file-remote-p) ;; as per Michael Albinus
;; (recentf-mode 1)
 (setq recentf-max-menu-items 25)
 (global-set-key "\C-x\ \C-r" 'recentf-open-files)

 (add-hook 'desktop-save-hook 'tramp-cleanup-all-buffers) ;; per Michael Albinus again

;;From Andreas Politz on help-gnu-emacs
(defun vi-forward-word (arg)
  (interactive "p")
  (cond
   ((< arg 0)
    (forward-word arg))
   ((> arg 0)
    (if (looking-at "\\w")
        (setq arg (1+ arg)))
    (forward-word arg)
    (backward-word))))
(global-set-key (kbd "C-!") 'vi-forward-word)

;;I don't use the American typist convention of a double space to mark the end of a sentence
(setq sentence-end-double-space nil)

;; find tag at point without the nagging
;; from: http://blog.printf.net/articles/2007/10/15/productivity-a-year-on
(defun find-tag-at-point ()
  "*Find tag whose name contains TAGNAME.
  Identical to `find-tag' but does not prompt for
  tag when called interactively;  instead, uses
  tag around or before point."
    (interactive)
      (find-tag (if current-prefix-arg
                    (find-tag-tag "Find tag: "))
                (find-tag (find-tag-default))))

(global-set-key [f9] 'find-tag-at-point)

;;jabber
(add-to-list 'load-path "~/lisp/jabber")
(require 'jabber-autoloads)

;;shell-toggle - thierry.volpiatto recommended esh-toggle on help-gnu-emacs and I googled for this one
;; (add-to-list 'load-path "~/lisp/shell-toggle")
;; (autoload 'shell-toggle "shell-toggle"  "Toggles between the *shell* buffer and whatever buffer you are editing."  t)
;; (autoload 'shell-toggle-cd "shell-toggle"  "Pops up a shell-buffer and insert a \"cd <file-dir>\" command." t)
;; (global-set-key (kbd "C-=") 'shell-toggle)
;; (global-set-key (kbd "C-+") 'shell-toggle-cd)


;;recommended by Drew Adams on help-gnu-emacs - Delete Selection mode lets you treat an Emacs region much like a typical selection outside of Emacs: You can replace the region just by typing text, and kill the selected text just by hitting the Backspace key (‘DEL’).
(delete-selection-mode 1)

;;; show the full path and filename in the message area (from: http://www.emacswiki.org/emacs/McMahanEmacsMacros)
(defun path ()
  (interactive "*")
  (message "%s" buffer-file-name))

;;my own hooks for term mode arrow key bindings
(defun jjg-term-arrows ()
(local-set-key (kbd "<up>") 'term-send-up)
(local-set-key (kbd "<down>") 'term-send-down)
)
(add-hook 'term-mode-hook 'jjg-term-arrows)

;;windows numbering mode
(add-to-list 'load-path "~/lisp/window-numbering")
(require 'window-numbering)
(window-numbering-mode 1)

;;TRAMP: To allow sudo access on specific hosts (still perfecting, need to tweak it with a good regex)
 (require 'tramp)
 ;; (add-to-list 'tramp-default-proxies-alist
 ;;              '("192.168.7.166" "jonathan" "/ssh:%h:"))

;; (add-to-list 'tramp-default-proxies-alist
;;              '("192.168.7.166" "\\`root\\'" "/ssh:%h:"))

;;tail files
(add-to-list 'load-path "~/lisp/tail")
(require 'tail)

;;emacs-w3m
(add-to-list 'load-path "/home/jonathan/lisp/w3m-cvs/share/emacs/site-lisp/w3m/")
(require 'w3m-load)
(require 'mime-w3m)

;;org mode
(require 'org-install)
(add-to-list 'auto-mode-alist '("\\.org$" . org-mode))
(define-key global-map "\C-cl" 'org-store-link)
(define-key global-map "\C-ca" 'org-agenda)
(setq org-log-done t)

;; from a google; written by Andreas Röhler
(defun goto-column (column)
" "
(interactive "nColumn: ")
(if (< (current-column) column)
(forward-char (- column (current-column)))
(forward-char (apply '- (list (- (current-column) column))))))

;;----------------------------------------------------------------------------
;; Specific to envirnoment
;;----------------------------------------------------------------------------

;; ;; auto-activate ECB when running graphically - this is still not working
(cond
 ((eq window-system 'x)
  (custom-set-variables '(ecb-auto-activate t))
 )
)

;; specific to linux
(cond
 ((string-match "linux" system-configuration)
;;   (setq initial-frame-alist
;;       `((left . 0) (top . 0)
;;         (width . 250) (height . 70)))

;; from: http://www.emacswiki.org/cgi-bin/wiki/CopyAndPaste
(global-set-key [(shift delete)]   'clipboard-kill-region)
(global-set-key [(control insert)] 'clipboard-kill-ring-save)
(global-set-key [(shift insert)]   'clipboard-yank)

;; unfill region seems to be in aquamacs but not linux
(defun unfill-paragraph ()
  (interactive)
  (let ((fill-column (point-max)))
  (fill-paragraph nil)))

;; my own invention to make GNU emacs under linux work like aquamacs
(global-set-key (kbd "s-c") 'clipboard-kill-ring-save)
(global-set-key (kbd "s-v") 'clipboard-yank)
(global-set-key (kbd "s-x") 'clipboard-kill-region)

;;select whole buffer - S-a
(global-set-key (kbd "s-a") 'mark-whole-buffer)

;; set a font that I like (linux only) - No longer needed emacs 23 is pretty
;;(set-default-font "-adobe-courier-medium-r-normal--18-180-75-75-m-110-iso8859-1")

(setq org-agenda-files (list "~/org/activesap.org"
                             "~/org/housekeeping.org"
                             "~/org/ruby.org"))

  )
)

;;----------------------------------------------------------------------------
;; From: http://www.emacswiki.org/cgi-bin/wiki/TrampMode sudo find file as root
;;----------------------------------------------------------------------------
;; (defvar find-file-root-prefix (if (featurep 'xemacs) "/[sudo/root@localhost]" "/sudo:root@localhost:" )
;;   "*The filename prefix used to open a file with `find-file-root'.")

;; (defvar find-file-root-history nil
;;   "History list for files found using `find-file-root'.")

;; (defvar find-file-root-hook nil
;;   "Normal hook for functions to run after finding a \"root\" file.")

;; (defun find-file-root ()
;;   "*Open a file as the root user.
;;    Prepends `find-file-root-prefix' to the selected file name so that it
;;    maybe accessed via the corresponding tramp method."

;;   (interactive)
;;   (require 'tramp)
;;   (let* ( ;; We bind the variable `file-name-history' locally so we can
;;          ;; use a separate history list for "root" files.
;;          (file-name-history find-file-root-history)
;;          (name (or buffer-file-name default-directory))
;;          (tramp (and (tramp-tramp-file-p name)
;;                      (tramp-dissect-file-name name)))
;;          path dir file)

;;     ;; If called from a "root" file, we need to fix up the path.
;;     (when tramp
;;       (setq path (tramp-file-name-path tramp)
;;             dir (file-name-directory path)))

;;     (when (setq file (read-file-name "Find file (UID = 0): " dir path))
;;       (find-file (concat find-file-root-prefix file))
;;       ;; If this all succeeded save our new history list.
;;       (setq find-file-root-history file-name-history)
;;       ;; allow some user customization
;;       (run-hooks 'find-file-root-hook))))

;; (global-set-key [(control x) (control y)] 'find-file-root)


;;tramp header changes from Paul R. on help-gnu-emacs
(defun my-tramp-header-line-function ()
  (when (string-match "^/su\\(do\\)?:" default-directory)
    (setq header-line-format
          (format-mode-line "----- THIS BUFFER IS VISITED WITH ROOT PRIVILEGES -----"
                            'font-lock-warning-face))))

(add-hook 'find-file-hooks 'my-tramp-header-line-function)
(add-hook 'dired-mode-hook 'my-tramp-header-line-function)


;;----------------------------------------------------------------------------
;; Maximise "frame" at start - fine under linux; too large under aquamacs
;;----------------------------------------------------------------------------
(cond
 ((eq aquamacs-p 'nil)
   (add-to-list 'load-path "~/lisp/maxframe")
   (require 'maxframe)
   (add-hook 'window-setup-hook 'maximize-frame t)
))

;;maximize frame function for darwin - by Nurullah Akkaya on help-gnu-emacs
(defun na-resize-frame-big ()
  "Set size"
  (interactive)
  (set-frame-width (selected-frame) 178)
  (set-frame-height (selected-frame) 50 )
  (set-frame-position (selected-frame) 0 1))

;;----------------------------------------------------------------------------
;; Hardware specific keybindings
;;----------------------------------------------------------------------------
;; On apple hardware there is no overwrite key, only a help key
;;(global-set-key [help] 'overwrite-mode)

;; Cocoa emacs, for some bizarre reason DELETE key is bound to backward-delete-char-untabify
;;and make home and end behave in a non-mac way!
(if (string-match "darwin" (version))
( progn
(global-set-key (kbd "<kp-delete>") 'delete-char)
(global-set-key (kbd "<backspace>") 'backward-delete-char)
(global-set-key (kbd "<home>") 'move-beginning-of-line)
(global-set-key (kbd "<end>") 'move-end-of-line)

;;tramp >su (to sudoer = jjg2) >sudo
(add-to-list 'tramp-default-proxies-alist
                  '("\\`localhost\\'" "\\`root\\'" "/su:jjg2@%h:"))

;;maximize frame on darwin
(na-resize-frame-big)
;;from: http://d.hatena.ne.jp/papamitra/20060924/synergy
;; (setq mac-command-modifier 'control)
;; (setq mac-option-modifier 'meta)
) )

;; specific to sparc hardware - make alt the meta key - http://www.emacswiki.org/cgi-bin/wiki/MetaKeyProblems
(cond ((string-match "sparc" system-configuration)
    (setq x-alt-keysym 'meta)  ) )

;;----------------------------------------------------------------------------
;; STARTUP
;; Open a shell upon startup
;; based on: http://infolab.stanford.edu/~manku/dotemacs.html
;;----------------------------------------------------------------------------

;;only want shell if running graphically -non graphically want all the space
;;and want rapid shutdown
(cond
 ((string-match "f" jjgnox)
;; (split-window-vertically)      ;; want two windows at startup
;; (other-window 1)               ;; move to other window
   (term "/bin/bash")
   (rename-buffer "term-first")   ;; rename it
   (switch-to-buffer "*scratch*")
;; (other-window 1)               ;; move back to first window
;; (enlarge-window 10)
))

;;----------------------------------------------------------------------------
;; from: http://www.emacswiki.org/emacs/buffer-move.el
;;----------------------------------------------------------------------------
(add-to-list 'load-path "~/lisp/buffer-move")
(require 'buffer-move)
(global-set-key (kbd "<C-S-up>")     'buf-move-up)
(global-set-key (kbd "<C-S-down>")   'buf-move-down)
(global-set-key (kbd "<C-S-left>")   'buf-move-left)
(global-set-key (kbd "<C-S-right>")  'buf-move-right)

;;----------------------------------------------------------------------------
;; Wanderlust, easy peasy...
;;----------------------------------------------------------------------------
;; load wanderlust
(autoload 'wl "wl" "Wanderlust" t)
(autoload 'wl-other-frame "wl" "Wanderlust on new frame." t)
(autoload 'wl-draft "wl-draft" "Write draft with Wanderlust." t)

;; IMAP
(setq elmo-imap4-default-server "mail.groll.co.za")
(setq elmo-imap4-default-authenticate-type 'clear)
(setq elmo-imap4-default-port '993)
(setq elmo-imap4-default-stream-type 'ssl)

;; emacs-fu wl iii:
;;from http://emacs-fu.blogspot.com/2010/02/i-have-been-using-wanderlust-e-mail.html
(setq mel-b-ccl-module nil)
(setq mel-q-ccl-module nil)
(setq base64-external-encoder '("mimencode"))
(setq base64-external-decoder '("mimencode" "-u"))
(setq base64-external-decoder-option-to-specify-file '("-o"))
(setq quoted-printable-external-encoder '("mimencode" "-q"))
(setq quoted-printable-external-decoder '("mimencode" "-q" "-u"))
(setq quoted-printable-external-decoder-option-to-specify-file '("-o"))
(setq base64-internal-decoding-limit 0)
(setq base64-internal-encoding-limit 0)
(setq quoted-printable-internal-decoding-limit 0)
(setq quoted-printable-internal-encoding-limit 0)

(setq-default mime-transfer-level 8)
(setq mime-header-accept-quoted-encoded-words t)

(setq user-full-name "Jonathan Groll")
(setq wl-local-domain "groll.co.za")
(setq wl-message-id-domain "groll.co.za!!")

;;for sending mails from home only - home is with an X windows emacs
(cond
 ((string-match "f" jjgnox)
(setq wl-smtp-connection-type 'starttls)
(setq wl-smtp-posting-port 25)
(setq wl-smtp-authenticate-type "plain")
(setq wl-smtp-posting-user "jjg")
(setq wl-smtp-posting-server "mail.groll.co.za")
(setq user-mail-address (concat wl-smtp-posting-user "@" wl-local-domain))
))


(setq wl-default-folder "%inbox_jon")
(setq wl-default-spec "%")
(setq wl-folder-check-async t)

(autoload 'wl-user-agent-compose "wl-draft" nil t)
(if (boundp 'mail-user-agent)
    (setq mail-user-agent 'wl-user-agent))
(if (fboundp 'define-mail-user-agent)
    (define-mail-user-agent
      'wl-user-agent
      'wl-user-agent-compose
      'wl-draft-send
      'wl-draft-kill
      'mail-send-hook))

;; BBDB used for address management with Wanderlust
(setq
bbdb-use-pop-up nil  ;; don't waste any precious screen real estate on BBDB
bbdb-offer-save 1 ;; 1 means save-without-asking
;;bbdb-use-pop-up t ;; allow popups for addresses
bbdb-electric-p t ;; be disposable with SPC
;;bbdb-popup-target-lines 1 ;; very small
bbdb-dwim-net-address-allow-redundancy t ;; always use full name
bbdb-quiet-about-name-mismatches 2 ;; show name-mismatches 2 secs
bbdb-always-add-address t ;; add new addresses to existing...
;; ...contacts automatically
;;bbdb-canonicalize-redundant-nets-p t ;; x@foo.bar.cx => x@bar.cx
bbdb-completion-type nil ;; complete on anything
bbdb-complete-name-allow-cycling t ;; cycle through matches
;; this only works partially
bbbd-message-caching-enabled t ;; be fast
bbdb-use-alternate-names t ;; use AKA
bbdb-elided-display t ;; single-line addresses

;; auto-create addresses from mail
bbdb/mail-auto-create-p 'bbdb-ignore-some-messages-hook
;; bbdb-ignore-some-messages-alist ;; don't ask about fake addresses
;; NOTE: there can be only one entry per header (such as To, From)
;; http://flex.ee.uec.ac.jp/texi/bbdb/bbdb_11.html

;; '(( "From" . "no.?reply\\|DAEMON\\|daemon\\|facebookmail\\|twitter")))

)

;; an attempt to make  wm scroll work as I like: (doesn't do it for MIME buffers)
(setq next-screen-context-lines 0)


;;----------------------------------------------------------------------------
;; I keep customization in a separate file (aquamacs is different)
;;----------------------------------------------------------------------------
;;Load customization file
(cond
 ((eq aquamacs-p 'nil)

  (setq custom-file "~/.emacs.d/custom.el")
  (load-file custom-file)

))


;; Allow for uppercase/downcase of region which is otherwise disabled
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)
