;;; early-init.el -*- lexical-binding: t; -*-

;; This file is loaded very early in the startup process, before graphical
;; elements and package.el (which I replace with straight.el) have been
;; initialised. Therefore, this file is a prime candidate for some impactful
;; optimisations.

;;; Startup Optimisations

(defvar my-gc-cons-threshold 16777216 ; 16 mb
  "The default value for `gc-cons-threshold' for use after initialisation.
If you experience freezing, decrease this. If you experience
stuttering, increase this.")

(defvar my--file-name-handler-alist file-name-handler-alist
  "A backup of `file-name-handler-alist'.
This is used by `my//remove-startup-optimizations' to restore the
original value of `file-name-handler-alist'.")

;; Prevent garbage collection during initialisation, since it is a big
;; contributor to startup times.
(setq gc-cons-threshold most-positive-fixnum)

;; As this is consulted on every `require', `load' and various path/io
;; functions, disable it during initialisation for a minor performance
;; boost. This is OK to do since it should not be needed during initialisation
;; anyway.
(setq file-name-handler-alist nil)

(defun my//remove-startup-optimizations ()
  "Restore variables modified for optimisation during startup.
This function sets garbage collection settings back to a
reasonable default (`my-gc-cons-threshold') and restores the
default value of `file-name-handler-alist'."
  (setq-default gc-cons-threshold my-gc-cons-threshold)
  (setq file-name-handler-alist my--file-name-handler-alist))

(add-hook 'emacs-startup-hook #'my//remove-startup-optimizations)

;;; GUI

;; Disable unwanted GUI elements early in order to avoid glitches and improve
;; startup time.
(setq tool-bar-mode nil
      menu-bar-mode nil)
(set-scroll-bar-mode nil)

;; Resizing the Emacs frame can be a terribly expensive part of changing the
;; font. By inhibiting this, startup times are easily halved with fonts that are
;; larger than the system default.
(setq frame-inhibit-implied-resize t)

;; Ignore X resources; its settings would be redundant with the other settings
;; in this file and can conflict with later configuration (particularly where
;; the cursor color is concerned).
(advice-add #'x-apply-session-resources :override #'ignore)

;;; Farewell, package.el

;; I use straight.el instead!
(setq package-enable-at-startup nil)
