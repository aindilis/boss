(defun boss-visit-etags ()
 (interactive)
 (if (file-exists-p (concat frdcsa-internal-codebases "/boss/data/TAGS"))
  (visit-tags-table (concat frdcsa-internal-codebases "/boss/data/TAGS"))
  (message "note-to-self: consider building the TAGS table at this point")))

(boss-visit-etags)

(global-set-key "\C-cbs" 'boss-quick-grep)
(global-set-key "\C-cbS" 'boss-search)
(global-set-key "\C-cboe" 'boss-open-examples-for-function)
(global-set-key "\C-cbr" 'boss-rebuild-etags)
(global-set-key "\C-cboic" 'boss-util-insert-new-boss-config-script)
(global-set-key "\C-cboim" 'boss-util-insert-new-boss-methodmaker-module)
(global-set-key "\C-cboiM" 'boss-util-insert-new-boss-moose-module)
(global-set-key "\C-cboie" 'boss-util-insert-new-export)
(global-set-key "\C-cboio" 'boss-util-insert-new-export-ok)
(global-set-key "\C-crert" 'boss-jump-to-sample-tests)

(defun boss-new-perl-func ()
 "Template for a new perl function"
 (interactive)
 (insert
  (concat "sub "
   (read-from-minibuffer "SUB:")
   "{\n\tmy ($self,%args) = (shift,@_);\n}")))

(defun boss-util-insert-new-boss-config-script ()
 ""
 (interactive)
 (insert (shell-command-to-string "cat /var/lib/myfrdcsa/codebases/internal/boss/templates/script-with-boss-config/script.pl")))

(defun boss-util-insert-new-boss-moose-module ()
 ""
 (interactive)
 (insert (shell-command-to-string "cat /var/lib/myfrdcsa/codebases/internal/boss/templates/moose-application/APP/Class.pm")))

(defun boss-util-insert-new-boss-methodmaker-module ()
 ""
 (interactive)
 (insert (shell-command-to-string "cat /var/lib/myfrdcsa/codebases/internal/boss/templates/oo-perl-application/APP/Class.pm")))

(defun boss-util-insert-new-export ()
 ""
 (interactive)
 (insert (shell-command-to-string "cat /var/lib/myfrdcsa/codebases/internal/boss/templates/script-with-boss-config/export.pl")))

(defun boss-util-insert-new-export-ok ()
 ""
 (interactive)
 (insert (shell-command-to-string "cat /var/lib/myfrdcsa/codebases/internal/boss/templates/script-with-boss-config/export-ok.pl")))

(defun boss-jump-to-sample-tests ()
 "Jump to the sample tests directory"
 (interactive)
 (ffap "/var/lib/myfrdcsa/codebases/internal/boss/sample-tests"))

(defun boss-search (&optional search)
 ""
 (interactive)
 (run-in-shell (concat "boss search "
		(shell-quote-argument (or search (read-from-minibuffer "BOSS Search: "))))))

(defun boss-quick-grep (&optional search)
 ""
 (interactive)
 (run-in-shell
  (concat "boss quick_grep "
   (shell-quote-argument (or search (read-from-minibuffer "BOSS Quick Grep: "))))))

(defun boss-rebuild-etags ()
 (interactive)
 (run-in-shell "boss etags")
 (boss-visit-etags))


;; boss needs functions for providing examples of how to code certain
;; things

(defun boss-open-examples-for-function (&optional function-arg)
 (interactive)
 (boss-quick-grep
  (or
   function-arg
   (prin1-to-string (kmax-function-macro-or-special-form-at-point))
   (completing-read "Function for reference: " (kmax-list-all-functions)))))
