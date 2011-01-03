;; -*- mode: emacs-lisp -*-

;;My Mail mode hook, I like auto fill and M-Tab for bbdb complete gets caught by window manager
(defun my-mail-mode-hook ()
  (local-set-key (kbd "C-c t") 'bbdb-complete-name)
  (auto-fill-mode 't)
  )
(add-hook 'mail-mode-hook 'my-mail-mode-hook)

(setq

 ;; Cache settings
 wl-plugged t
 elmo-imap4-use-cache t
 wl-ask-range nil

 elmo-message-fetch-confirm nil
 elmo-message-fetch-threshold 2500000
 wl-from (concat user-full-name " <" user-mail-address ">")

 wl-summary-always-sticky-folder-list t

 ;; Settings mostly from emacs-fu, or inspired by the post at:
 ;; http://emacs-fu.blogspot.com/2009/06/e-mail-with-wanderlust.html
 wl-folder-window-width 25
 wl-fcc "%sent"                       ;; sent msgs go to the "sent"-folder
 wl-fcc-force-as-read t               ;; mark sent messages as read
 wl-default-folder "%inbox_jon"       ;; my main inbox


 ;;still no biff joy, when I get the time...
 ;; biff- automatic folder checking
 ;; wl-biff-check-folder-list '("%inbox")
 ;; wl-biff-check-interval 40
 ;; wl-biff-use-idle-timer nil

 ;; hide many fields from message buffers
 wl-message-ignored-field-list '("^.*:")
 wl-message-visible-field-list
 '("^\\(To\\|Cc\\):"
   "^Subject:"
   "^\\(From\\|Reply-To\\):"
   "^Organization:"
   "^User-Agent:"
   "^\\(Posted\\|Date\\):"
   )
 wl-message-sort-field-list
 '("^From"
   "^To"
   "^Cc"
   "^Organization:"
   "^X-Attribution:"
   "^Subject"
   "^Date"
   )

 ;; my own (jjg) settings from reading the info pages
;; wl-insert-mail-reply-to t

 ;; from: http://emacs-fu.blogspot.com/2009/09/wanderlust-tips-and-tricks.html
 wl-forward-subject-prefix "Fwd: "   ;; use "Fwd: " not "Forward: "

 ;; need to work on wl-ignored-forwarded-headers
;;  wl-ignored-forwarded-headers   `\\(received\\|return-path\\|x-uidl\\|X-\\|Delivered-To|DKIM-Signature\\|DomainKey-Signature\\|Message-ID\\|References\\|MIME-Version\\|Content-Type\\|In-Reply-To\\|User-Agent\\)'
;;wl-ignored-forwarded-headers "(\\received\\|return-path\\|x-uidl\\)"
wl-ignored-forwarded-headers (concat
                        "\\(Delivered-To*\\|X-Original-To*\\|received*\\|X-*\\|return-path*\\|User-Agent*\\|Message-Id*\\|DKIM-Signature*\\|DomainKey-Signature*\\|MIME-Version*\\|In-Reply-To*\\|References:*\\|X-BeenThere*\\|X-Mailman-Version*\\|Precedence:*\\|Reply-To*\\|List-Id*\\|List-Unsubscribe*\\|List-Archive*\\|List-Post*\\|List-Help*\\|List-Subscribe*\\|Content-Type*\\|Content-Transfer-Encoding*\\|Errors-To*\\)"

;;wl-draft-elide-ellipsis "[... original message snipped ...]"

; type specs; there can be no
;;                        "\\(Delivered-To*\\)" ; type specs; there can be no
;;                        "\\(Delivered-To*\\)" ; type specs; there can be no
;;"\\(X-Original-To*\\)"
;;                        "^"                ; beginning of line is required
                        ;; "^\\(received\\)" ; there may be a "template <...>"
                        ;; "^\\(return-path\\)" ; type specs; there can be no
                        ;; "^\\(X-Original-To\\)" ; type specs; there can be no
                        ;; "^\\(Delivered-To\\)" ; type specs; there can be no
                        ;; "^\\(User-Agent\\)" ; type specs; there can be no
                        )

 )


;; When I want to reply to someone, I don't need to CC myself, but I did like the previous mailing list reply behaviour:
;;
;; from a WL-mailinglist post by David Bremner
;; May want to uncomment code in the next couple of blocks for replying to mailing lists.
;; Default behaviour where I define my own mailing lists may be better
;; Invert behaviour of with and without argument replies.
;; just the author
(setq wl-draft-reply-without-argument-list
      '(("Reply-To" ("Reply-To") nil nil)
        ("Mail-Reply-To" ("Mail-Reply-To") nil nil)
        ("From" ("From") nil nil)))

;; (setq wl-draft-reply-with-argument-list
;;       '(("Followup-To" nil nil ("Followup-To"))
;;         ("Mail-Followup-To" ("Mail-Followup-To") nil ("Newsgroups"))
;;         ("Reply-To" ("Reply-To") ("To" "Cc" "From") ("Newsgroups"))
;;         ("From" ("From") ("To" "Cc") ("Newsgroups"))))


;; ;; ;;from 13.7.1 of the info
;; ;; (setq wl-subscribed-mailing-list
;; ;;       '("hivemind@hivemind.net"
;; ;;         "clug-tech@clug.org.za"
;; ;;         "clug-chat@clug.org.za"
;; ;;         "The hivemind <hivemind@hivemind.net>"
;; ;;         ;; "ml@xxxxxxxxxxx" ...
;; ;;         ))



;; ;;      (defun wl-mailing-list-addresses ()
;; ;;        (let (list-addrs)
;; ;;          (dolist (to (mapcar
;; ;;                        (lambda (addr)
;; ;;                             (nth 1 (std11-extract-address-components addr)))
;; ;;                         (wl-parse-addresses
;; ;;                            (wl-concat-list
;; ;;                                (elmo-multiple-fields-body-list (list "To" "Cc"))
;; ;;                                   ","))))
;; ;;            (when (elmo-string-matched-member to wl-subscribed-mailing-list t)
;; ;;              (setq list-addrs (cons to list-addrs))))
;; ;;          (nreverse list-addrs)))

;; ;;      (setq wl-draft-reply-with-argument-list
;; ;;            '((wl-mailing-list-addresses . (wl-mailing-list-addresses nil nil))
;; ;;              ("Reply-To" . (("Reply-To") nil nil))
;; ;;              ("Mail-Reply-To" . (("Reply-To") nil nil))
;; ;;              ("From" . (("From") nil nil))))



;;from http://www.emacswiki.org/emacs/WlFaq
(setq mime-edit-split-message nil)

;;-----------------------------------
;; Mass of settings from http://dis-dot-dat.blogspot.com/2010/04/my-wanderlust-setup
;; Also seems he took a lot from Emacs-fu!
;;-----------------------------------
(setq wl-summary-line-format "%n%T%P %D.%M %h:%m %t[%20(%c%f%)] %s")
;;(setq wl-summary-line-format "%n%T%P %D/%M %h:%m %t%[%20(%c %f%) %] %s")
;;(setq wl-summary-line-format "%n%T%P %D/%M (%W) %h:%m %t%[%25(%c %f%) %] %s")
(setq wl-summary-width nil)

;; from http://osdir.com/ml/mail.wanderlust.general/2008-05/msg00005.html
(autoload 'mu-cite-original "mu-cite" nil t)
(add-hook 'mail-citation-hook 'mu-cite-original)
(setq mu-cite-prefix-format '("> "))
(setq mu-cite-cited-prefix-regexp nil)
(setq mu-cite-top-format '("On " date ", " from " wrote:\n\n"))


;;(add-to-list 'load-path "/usr/share/emacs23/site-lisp/mu-cite/")
;; (require 'mu-cite)
;; (add-hook 'mail-citation-hook 'mu-cite-original)
;; (setq mu-cite-top-format
;;       '("On " date "," full-name " wrote:\n"))

;;{This code seems to have been written by James Shuttleworth to drop his .sig at the bottom of replies

;; (setq signature-file-name ".signature"
;;       signature-insert-at-eof t
;;       signature-delete-blank-lines-at-eof t
;;       mu-cite-prefix-format (quote (">")) ; default to >, no questions asked, rather than name
;;       )

;; ;; (add-hook
;; ;;  'wl-init-hook
;; ;;  '(lambda ()
;; ;;     ;; Add support for (signature . "filename")
;; ;;     (unless (assq 'signature wl-draft-config-sub-func-alist)
;; ;;       (wl-append wl-draft-config-sub-func-alist
;; ;;                  '((signature . wl-draft-config-sub-signature))))

;; ;;     (defun mime-edit-insert-signature (&optional arg)
;; ;;       "Redefine to insert a signature file directly, not as a tag."
;; ;;       (interactive "P")
;; ;;       (insert-signature arg))
;; ;;     ))

;; ;; (defun wl-draft-config-sub-signature (content)
;; ;;   "Insert the signature at the end of the MIME message."
;; ;;   (let ((signature-insert-at-eof nil)
;; ;;         (signature-file-name content))
;; ;;     (goto-char (mime-edit-content-end))
;; ;;     (insert-signature)))
;;}

;;Get BBDB workiing
(require 'bbdb-wl)
(bbdb-wl-setup)
(define-key wl-draft-mode-map (kbd "") 'bbdb-complete-name)

(defun djcb-wl-draft-subject-check ()
  "check whether the message has a subject before sending"
  (if (and (< (length (std11-field-body "Subject")) 1)
           (null (y-or-n-p "No subject! Send current draft?")))
      (error "Abort.")))

;; note, this check could cause some false positives; anyway, better
;; safe than sorry...
(defun djcb-wl-draft-attachment-check ()
  "if attachment is mention but none included, warn the the user"
  (save-excursion
    (goto-char 0)
    (unless ;; don't we have an attachment?

        (re-search-forward "^Content-Disposition: attachment" nil t)
      (when ;; no attachment; did we mention an attachment?
          (re-search-forward "attach" nil t)
        (unless (y-or-n-p "Possibly misssibly missing an attachment. Send current draft?")
          (error "Abort."))))))

(add-hook 'wl-mail-send-pre-hook 'djcb-wl-draft-subject-check)
(add-hook 'wl-mail-send-pre-hook 'djcb-wl-draft-attachment-check)

;Auto add signature on draft edit
(remove-hook 'wl-draft-send-hook 'wl-draft-config-exec)
(add-hook 'wl-mail-setup-hook 'wl-draft-config-exec)
                                        ;Stop mime errors when sending to AOL/others?
                                        ; osdir.com/ml/mail.wanderlust.general/2006-10/msg00007.html
                                        ;(setq-default mime-transfer-level 8)
;; activate line below only if needed
;;(setq smtp-use-8bitmime nil)

;; The occasional UTF8 issue:
;; an incoming mail has
;; From: "=?utf-8?B?QWxsaWFuY2UgRnJhbsOnYWlzZSBvZiBDYXBlIFRvd24=?=" <culture.cpt@alliance.org.za>
;; causing the summary buffer to not decode the above UTF string in the From: field
;; the mail displays fine in the message buffer
;; the mail has
;; Content-Type: multipart/alternative; boundary="495df776cec38115e3aca56b89d0ba11"
;; appending this to the end of the above fixed things:
;;  ;charset=iso-8859-1; format=flowed
;; I think Yavor Doganov was describing the same here:
;; http://blog.gmane.org/gmane.mail.wanderlust.general/month=20060901

;; Here is another possible fix:
;; from http://www.tamaru.kuee.kyoto-u.ac.jp/kada/wl/unicode.html
;;(require 'un-define)
(eval-after-load
    "mime-edit"
  '(let ((text (assoc "text" mime-content-types)))
     (set-alist 'text "plain"
                '(("charset" "" "ISO-2022-JP" "US-ASCII"
                   "ISO-8859-1" "ISO-8859-8" "UTF-8")))
     (set-alist 'mime-content-types "text" (cdr text))))

;; from: http://www.emacswiki.org/emacs/WlFormatFlowed
;; Reading format=flowed
(autoload 'fill-flowed "flow-fill")
(add-hook 'mime-display-text/plain-hook
          (lambda ()
            ;; (when (string= "flowed"
            ;;               (cdr (assoc "format"
            ;;                                  (mime-content-type-parameters
            ;;                                   (mime-entity-content-type entity)))))
            (visual-line-mode)
            (fill-flowed)))
;;writing format=flowed
;;(setq mime-edit-insert-tag "text" "plain" "; format=flowed")
;;(mime-edit-insert-tag "text" "plain" "; format = flowed")
;; (eval-after-load "mime-edit" '(unless (functionp 'mime-edit-insert-text-file) (defun mime-edit-insert-text-file (file) "Insert a text file. Charset is automatically obtained from the `charsets-mime-charset-alist'." (interactive "fInsert file as MIME text part: \n") (let ((type "text") (subtype "plain") (parameters (concat "\nContent-Disposition: attachment; filename=" (std11-wrap-as-quoted-string (file-name-nondirectory file))))) (mime-edit-insert-tag type subtype parameters) (insert-file-contents file))) (add-hook 'mime-edit-load-hook '(lambda () (define-key mime-edit-mode-entity-map "i" 'mime-edit-insert-text-file))) )) (Eval-after-load "mime-edit" '(unless (functionp' mime-edit-insert-text-file) (defun mime-edit-insert-text-file (file) "Insert a text file. Charset is automatically obtained from the `charsets-mime-charset-alist '." (interactive "fInsert file as MIME text part: \ n") (let ((type "text") (subtype "plain") (parameters (concat "\ nContent -Disposition: attachment; filename = "(std11-wrap-as-quoted-string (file-name-nondirectory file ))))) (mime-edit-insert-tag type subtype parameters) (insert-file-contents file) )) (add-hook 'mime-edit-load-hook' (lambda () (define-key mime-edit-mode-entity-map "i" 'mime-edit-insert-text-file)))))


;; from http://www.huoc.org/hacks/dotemacs/wlrc.el
;;;; Biff

;; It does not seem like WL provides a function to list all the
;; folders it knows by name, so here's one.
(defun my-wl-folder-name-list ()
  "Return a list of all folder names."
  ;; XXX: It seems the first folder always has ID 1.
  ;; `wl-folder-get-next-folder' is broken in my version of WL: it
  ;; wouldn't accept folder names, so we have to rely on IDs.
  (let (folder-list
        (id 1)
        (entity (wl-folder-get-folder-name-by-id 1)))
    (setq folder-list (list entity))
    (setq entity (wl-folder-get-next-folder id))
    (while entity
      (setq id (wl-folder-get-entity-id entity))
      (setq folder-list (cons entity folder-list))
      (setq entity (wl-folder-get-next-folder id)))
    folder-list))





;; XXX: The doc is wrong, `wl-biff-check-folder-list' cannot hold
;; regexps meaningfully. We have to list all our folders. However,
;; this can only be done once WL is started, so we leave it to the
;; main .emacs.
;; (defun my-mail-notify ()
;;   "Notify through Ratpoison that new mail has arrived."
;;   (ratpoison-command "echo New mail"))
;; (defun my-wl-biff ()
;;   "Set up biff on all WL folders."
;;   (setq wl-biff-check-folder-list (my-wl-folder-name-list)
;;         wl-biff-check-interval 40)
;;   ;;  (add-hook 'wl-biff-notify-hook 'my-mail-notify)
;;   (wl-biff-start))

;; (my-wl-biff)

;; My IMAP server (Dovecot) interprets the call to
;; `elmo-folder-exists-p' as a client query that should unmark new
;; mails and leave them as simply Unread (instead of Recent).
(defun my-elmo-folder-exists-p (folder) t)
(defadvice wl-biff-check-folders (around my-disable-exists-test activate)
  "Disable `elmo-folder-exists-p' and make it return t."
  (let ((real-elmo-folder-exists-p
         (symbol-function 'elmo-folder-exists-p)))
    (fset 'elmo-folder-exists-p (symbol-function 'my-elmo-folder-exists-p))
    ad-do-it
    (fset 'elmo-folder-exists-p real-elmo-folder-exists-p)))

;;from: http://paste.lisp.org/display/112520
;; Create opened thread.
(setq wl-thread-insert-opened t)

;; Open new frame for draft buffer.
(setq wl-draft-use-frame t)

;; non-verbose User-Agent: field
(setq wl-generate-mailer-string-function
      'wl-generate-user-agent-string-1)

;; Wide window for draft buffer.
(setq wl-draft-reply-buffer-style 'full)
(setq wl-message-id-domain "groll.co.za")

;;Cobbled together from posts by Erik Hetzner & Harald Judt to wl-en@lists.airs.net
(defun mime-edit-insert-multiple-files ()
  "Insert MIME parts from multiple files."
  (interactive)
  (let ((dir default-directory))
    (let ((next-file (expand-file-name
                      (read-file-name "Insert file as MIME message: " dir))))
      (setq file-list (file-expand-wildcards next-file))
      (while (car file-list)
        (mime-edit-insert-file (car file-list) )
        (setq file-list (cdr file-list))))))

(global-set-key "\C-c\C-x\C-a" 'mime-edit-insert-multiple-files)
;;(define-key wl-draft-mode-map (kbd "<C-tab>") 'bbdb-complete-name)
(global-set-key  (kbd "C-c C-x t") 'bbdb-complete-name)


;;See who I sent mail to when looking at the sent folders (rather than my name)
(defun jjg-add-domain (list-element)
  (concat list-element "@" wl-local-domain))
(setq wl-user-mail-address-list (mapcar 'jjg-add-domain '("lists" "jjg" "jonathan")))
(setq wl-summary-showto-folder-regexp ".*sent.*")
(setq wl-summary-from-function 'wl-summary-default-from)

;;For Ubuntu 10.10 - can't get GNUTLS to talk to my dovecot imapd
(setq ssl-program-name "openssl")
(setq ssl-program-arguments '("s_client" "-host" host "-port" service "-verify"
                             "0" "-CApath" "/usr/lib/ssl/certs" "-quiet"))

;; Templates - I use three different email accounts
  (setq wl-template-alist
  '(
    ("g"
     (wl-smtp-posting-user . "jjg")
     (user-mail-address . (concat wl-smtp-posting-user "@" wl-local-domain))
     (wl-from . (concat user-full-name  " <" user-mail-address ">"))
     ("From" . wl-from)
;;     ("Mail-Reply-To" . user-mail-address)
     ("Reply-To" . user-mail-address)
     ("Fcc" . (concat "%sent:" wl-smtp-posting-user "/login:993"))
    )
    ("l"
     (wl-smtp-posting-user . "lists")
     (user-mail-address . (concat wl-smtp-posting-user "@" wl-local-domain))
     (wl-from . (concat user-full-name  " <" user-mail-address ">"))
     ("From" . wl-from)
;;     ("Mail-Reply-To" . "")
;;     ("Reply-To" . user-mail-address)
     ("Fcc" . (concat "%sent:" wl-smtp-posting-user "/login:993"))
    )
    ("j"
     (wl-smtp-posting-user . "jonathan")
     (user-mail-address . (concat wl-smtp-posting-user "@" wl-local-domain))
     (wl-from . (concat user-full-name  " <" user-mail-address ">"))
     ("From" . wl-from)
;;     ("Mail-Reply-To" . user-mail-address)
     ("Reply-To" . user-mail-address)
     ("Fcc" . "%sent")
;;     ("Content-Type" . "text/plain; charset=UTF-8; format=flowed")
    )
    ))

;; Automatically select the correct template (account) based on which folder I'm visiting
(setq wl-draft-config-matchone t)
(setq wl-draft-config-alist
       '(
          (

           ( and (string-match ".*hivemind\\|.*lists\\|.*spam" wl-draft-parent-folder) )
            (template . "l")
            (bottom . "\nCheers,\nJonathan\n--\n")
            (bottom-file . ".signature")
            )

          (
           (  and (string-match ".*jjg.*" wl-draft-parent-folder) )
            (template . "g")
            (bottom . "\nCheers,\nJonathan\n--\n")
            (bottom-file . ".signature")
            )

          ;;default
          (
           (  and (string-match "1" "1") )
            (template . "j")
            (bottom . "\nCheers,\nJJG\n--\n")
            (bottom-file . ".signature2")
            )
))
