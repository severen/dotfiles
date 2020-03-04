;;; init.el -*- lexical-binding: t; -*-

;; This file contains initialisation that must be done *before* loading the rest
;; of my configuration, which resides in `config.el'.

(when (version< emacs-version "28")
  (error
   "You are running Emacs %s. This config only supports Emacs 28.0 and higher."
   emacs-version))

;;; Config, Data, and Cache Directory Constants

(require 'xdg)

;; Starting with 28.0, Emacs is (somewhat) XDG BaseDir compliant!
;; Unfortunately, it needs some extra help in storing its data and cache files
;; somewhere other than the configuration directory. I define these here so that
;; I can use them later in this file and in `config.el'.

(defconst CONFIG-DIR (file-truename user-emacs-directory)
  "The path to Emacs' configuration directory.")
(defconst DATA-DIR
  (expand-file-name "emacs" (file-name-as-directory (xdg-data-home)))
  "The path to Emacs' data directory.")
(defconst CACHE-DIR
  (expand-file-name "emacs" (file-name-as-directory (xdg-cache-home)))
  "The path to Emacs' cache directory.")

;;; Measurement of Initialisation Time

(defun my/display-init-time ()
  "Measure and display the time taken to load the init files.
Note that this time is not completely indicative of the total
time taken until interactivity, but rather just the total time
taken to run init.el and any code it depends upon."
  (interactive)
  (message "Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                    (time-subtract after-init-time before-init-time)))
           gcs-done))

(add-hook 'emacs-startup-hook #'my/display-init-time t)

;;; Package Management

;; My package management setup is a combination of straight.el, which is an
;; improved alternative to package.el, and use-package, which provides an
;; effective way to declare and defer packages.

;;;; straight.el
;;;;; Configure

;; Store repositories/packages in an XDG BaseDir-compliant location.
(setq straight-base-dir DATA-DIR)

;; Hide the process buffer.
(setq straight-process-buffer " *straight-process*")

;; By default, straight.el will check installed packages for modifications on
;; startup. This behaviour adds a non-insignificant hit to the load time. To
;; avoid this, I configure straight.el to instead check for modifications via an
;; external file watcher if possible, or otherwise check for modifications when
;; a file is saved in Emacs. This entirely cuts out the load time hit, without
;; any loss in functionality, so long as watchexec and Python are installed.
(if (and (executable-find "watchexec")
         (executable-find "python3"))
    (setq straight-check-for-modifications '(watch-files find-when-checking))
  (setq straight-check-for-modifications '(check-on-save find-when-checking)))

;;;;; Bootstrap

(defvar bootstrap-version
  "The version of straight.el's bootstrap script to use.")

(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" DATA-DIR))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;;;; use-package

;; Install use-package and tell straight.el to use it.
(setq straight-use-package-by-default t)
(straight-use-package 'use-package)

;;; Load Main Configuration

(load (concat CONFIG-DIR "config.el") nil 'nomessage)
