;;; log-hours.el --- Hours spent working log

;; Copyright (C) 2004  Free Software Foundation, Inc.

;; Author: Debian User <adougher9@yahoo.com>
;; Keywords: 

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Hooks to create a log of  hours spent working on given projects, by
;; creating an overview of which buffers are visited

;;; Code:

(defun log-hours ()
  "Function to create  a log buffer containing all  the information we
need"
(interactive)
  (find-file-hooks)
(kill-buffer-hook)
(kill-emacs-hook)

(provide 'log-hours)
;;; log-hours.el ends here
