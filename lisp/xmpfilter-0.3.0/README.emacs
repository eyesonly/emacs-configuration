
Here's some elisp code to use xmpfilter.rb from emacs. It will guess which
mode (plain annotation, Test::Unit assertion or RSpec expectation generation)
applies.


(defadvice comment-dwim (around xmp-hack activate)
  ""
  (if (and (eq last-command 'comment-dwim)
           ;; TODO =>check
           )
      (insert "=>")
    ad-do-it))
;; (progn (ad-disable-advice 'comment-dwim 'around 'xmp-hack) (ad-update 'comment-dwim)) 

(defun xmp ()
  (interactive)
  (let ((line (current-line))
        (col  (current-column)))
    (shell-command-on-region 1 (point-max) (xmp-command) t t)
    (goto-line line)
    (move-to-column col)))

(defun xmp-command ()
  (cond ((save-excursion
           (goto-char 1)
           (search-forward "< Test::Unit::TestCase" nil t))
         "ruby -S xmpfilter.rb --unittest")
        ((save-excursion
           (goto-char 1)
           (re-search-forward "^context.+do$" nil t))
         "ruby -S xmpfilter.rb --spec")
        (t
         "ruby -S xmpfilter.rb")))

