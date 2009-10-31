; -*- Lisp -*-

; Setting the imap-ssl-program like this isn't strictly necessary, but
; I do it anyway since I'm paranoid. (I think it will default to
; `-ssl2' instead of `-tls1' if you don't do this.)
; (setq imap-ssl-program "openssl s_client -tls1 -connect %s:%p")

; Since I use gnus primarily for mail and not for reading News, I
; make my IMAP setting the default method for gnus.
(setq gnus-select-method '(nnimap "localhost"
                                  (nnimap-address "localhost")
;;                                  ((nnimap-list-pattern ("INBOX*")
                                  ))

;; there are no sources of email it must go fetch, process, and/or otherwise transfer in
(setq mail-sources nil)

;; disable nntp stuff
(setq gnus-nntp-server nil
      gnus-read-active-file nil
      gnus-save-newsrc-file nil
      gnus-read-newsrc-file nil
      gnus-check-new-newsgroups nil)

;;save copies in sent
(setq gnus-message-archive-method '(nnimap "localhost"))
(setq gnus-message-archive-group "nnimap+localhost:SENT")

;; Fetch only part of the article if we can.  I saw this in someone
;; else's .gnus
(setq gnus-read-active-file 'some)

;; Tree view for groups.  I like the organisational feel this has.
(add-hook 'gnus-group-mode-hook 'gnus-topic-mode)

;; Threads!  I hate reading un-threaded email -- especially mailing
;; lists.  This helps a ton!
(setq gnus-summary-thread-gathering-function
      'gnus-gather-threads-by-subject)

;;From Richard Riley's .gnu
(add-to-list 'gnus-secondary-select-methods
              '(nntp "wa"
                       (nntp-address "news.wa.co.za")
                       (nntp-port-number 119)
                       )
              )


;; Also, I prefer to see only the top level message.  If a message has
;; several replies or is part of a thread, only show the first
;; message.  'gnus-thread-ignore-subject' will ignore the subject and
;; look at 'In-Reply-To:' and 'References:' headers.
;; (setq gnus-thread-hide-subtree t)
;; (setq gnus-thread-ignore-subject t)

;; Change email address for work folder.  This is one of the most
;; interesting features of Gnus.  I plan on adding custom .sigs soon
;; for different mailing lists.
;; (setq gnus-posting-styles
;;       '((".*"
;;          (name "Mark A. Hershberger")
;;          ("X-URL" "http://mah.everybody.org/"))
;;         ("work"
;;          (address "mhershb@mcdermott.com"))
;;         ("everybody.org"
;;          (address "mah@everybody.org"))))