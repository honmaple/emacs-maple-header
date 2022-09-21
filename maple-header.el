;;; maple-header.el ---  file header auto insert or update.	-*- lexical-binding: t -*-

;; Copyright (C) 2015-2022 lin.jiang

;; Author: lin.jiang <mail@honmaple.com>
;; URL: https://github.com/honmaple/emacs-maple-header

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; file header auto insert or update.
;;

;;; Code:
(require 'autoinsert)

(defgroup maple-header nil
  "Auto update file header."
  :group 'maple)

(defcustom maple-header:lines 9
  "The number of search lines."
  :group 'maple-header
  :type 'integer)

(defcustom maple-header:auto-insert t
  "Whether auto insert header after create a new file."
  :group 'maple-header
  :type 'boolean)

(defcustom maple-header:auto-update t
  "Whether auto update header before save."
  :group 'maple-header
  :type 'boolean)

(defcustom maple-header:auto-insert-alist
  '(((ruby-mode . "Ruby program") nil
     "#!/usr/bin/env ruby\n"
     "# -*- encoding: utf-8 -*-\n"
     (maple-header:template) "\n")
    ((python-mode . "Python program") nil
     "#!/usr/bin/env python\n"
     "# -*- coding: utf-8 -*-\n"
     (maple-header:template) "\n")
    ((c-mode . "C program") nil
     "/*"
     (string-trim-left (maple-header:template " ")) "*/\n"
     "#include<stdio.h>\n"
     "#include<string.h>\n")
    ((sh-mode . "Shell script") nil
     "#!/bin/bash\n"
     (maple-header:template) "\n")
    ((go-mode . "Go program") nil
     "/*"
     (string-trim-left (maple-header:template " ")) "*/\n"
     "package main\n"))
  "The insert template list of header."
  :group 'maple-header
  :type '(list))

(defcustom maple-header:auto-update-alist
  '((filename . maple-header:update-filename)
    (email . maple-header:update-email)
    (modify . maple-header:update-modify))
  "The update list of header."
  :group 'maple-header
  :type '(list))

(defun maple-header:template(&optional prefix)
  "Template with PREFIX."
  (replace-regexp-in-string
   "^" (or prefix comment-start)
   (concat
    (make-string 80 ?*) "\n"
    "Copyright © " (substring (current-time-string) -4) " " (user-full-name) "\n"
    "File Name: " (file-name-nondirectory buffer-file-name) "\n"
    "Author: " (user-full-name)"\n"
    "Email: " user-mail-address "\n"
    "Created: " (format-time-string "%Y-%m-%d %T (%Z)" (current-time)) "\n"
    "Last Update: \n"
    "         By: \n"
    "Description: \n"
    (make-string 80 ?*))))

(defun maple-header:update-action(find replace &optional current-line)
  "FIND and REPLACE header with CURRENT-LINE."
  (save-excursion
    (unless current-line
      (goto-char (point-min)))
    (dotimes (_ (if current-line 1 maple-header:lines))
      (when (looking-at find)
        (let ((beg (match-beginning 2))
              (end (match-end 2)))
          (when (not (string= replace (string-trim-left (match-string 2))))
            (goto-char beg)
            (delete-region beg end)
            (insert " " replace))))
      (forward-line 1))))

(defun maple-header:update-filename(&optional current-line)
  "Update filename CURRENT-LINE."
  (interactive)
  (maple-header:update-action
   ".*\\(File Name:\\)\\(.*\\)"
   (file-name-nondirectory (buffer-file-name)) current-line))

(defun maple-header:update-email(&optional current-line)
  "Update email CURRENT-LINE."
  (interactive)
  (maple-header:update-action
   ".*\\(Email:\\)\\(.*\\)"
   user-mail-address current-line))

(defun maple-header:update-modify(&optional current-line)
  "Update modify CURRENT-LINE."
  (interactive)
  (if (apply 'derived-mode-p '(org-mode markdown-mode))
      (maple-header:update-action
       ".*\\(Modified:\\|MODIFIED:?\\)\\(.*\\)"
       (format-time-string "%Y-%02m-%02d %02H:%02M:%02S") current-line)
    (maple-header:update-action
     ".*\\([lL]ast[ -][uU]pdate:\\)\\(.*\\)"
     (let ((system-time-locale "en_US.UTF-8"))
       (format-time-string "%A %Y-%02m-%02d %02H:%02M:%02S (%Z)"))
     current-line)))

(defun maple-header:insert()
  "Header auto insert."
  (setq auto-insert-query nil
        auto-insert-alist maple-header:auto-insert-alist)
  (auto-insert-mode 1))

(defun maple-header:update()
  "Header auto update."
  (interactive)
  (let ((buffer-undo-list t))
    (save-excursion
      (goto-char (point-min))
      (dotimes (_ maple-header:lines)
        (cl-loop for item in maple-header:auto-update-alist
                 do (funcall (cdr item) t))
        (forward-line 1)))))

(defun maple-header-mode-on()
  "Enable maple header mode."
  (when maple-header:auto-insert
    (add-hook 'prog-mode-hook 'maple-header:insert))
  (when maple-header:auto-update
    (add-hook 'before-save-hook 'maple-header:update)))

(defun maple-header-mode-off()
  "Disable maple header mode."
  (remove-hook 'prog-mode-hook 'maple-header:insert)
  (remove-hook 'before-save-hook 'maple-header:update))

;;;###autoload
(define-minor-mode maple-header-mode
  "Maple header mode."
  :group      'maple-header
  :global     t
  (if maple-header-mode (maple-header-mode-on) (maple-header-mode-off)))

(provide 'maple-header)
;;; maple-header.el ends here
