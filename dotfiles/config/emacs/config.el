;;; config.el -*- lexical-binding: t; -*-

;; This is my personal Emacs configuration, heavily inspired by and based upon
;; the likes of Doom, Spacemacs, and countless other configurations.
;;
;; This file is laid out in a way that is inspired by literate programming,
;; where everything resides in one file, is organised under hierachical
;; headings, and is well-commented. One day I may use Org for this, but for now
;; this is a simple way to get most of Org's benefits.
;;
;; To view the outline of this file, press the keys `z m'. To undo this by
;; unfolding everything again, press `z r' (assuming you are viewing this file
;; with Evil and Outshine loaded).
;;
;; I follow some simple conventions when writing Emacs Lisp, which are
;; documented in conventions.org.

;; And here is my personal information:
(setq-default user-full-name "Severen Redwood"
              user-mail-address "severen@shrike.me")
;; Please change the above if you are copying this file.

;;;; A Note to Prospective Users

;; There is no guarantee that this will work on any systems other than my own,
;; nor am I interested in changing this.
;;
;; If you do like my configuration, I recommend that rather than copying it in
;; full, you read through it and adapt the parts that you may find useful into
;; your own configuration. After all, that is part of what makes Emacs fun, or
;; at least according to me.
;;
;; However, if you have found an error or mistake, or believe you have something
;; to add that I may find useful, you can submit a pull request to my dotfiles
;; repository on GitHub (severen/dotfiles).

;;; Core

;; This section contains some core definitions and configuration that are either
;; basic enough to not need a separate section or are needed by later sections.

;; TODO: Measure the time reloading takes (maybe?).
(defun my/reload-config ()
  "Reload the configuration file."
  (interactive)
  (message "Reloading configuration...")
  (load user-init-file nil 'nomessage)
  (message "Reloading configuration... done."))

;;;; Libraries

;; Libraries that are dependencies of either this file or packages loaded by
;; this file are declared here.

(require 'cl-lib)

(use-package git :defer t)

;;;; Variables and Constants

(defconst IS-LINUX (eq system-type 'gnu/linux)
  "Whether the current system is Linux or not.")
(defconst IS-WINDOWS (memq system-type '(cygwin windows-nt ms-dos))
  "Whether the current system is Windows or not.")

(defconst IS-VERBOSE (or (getenv "EMACS_VERBOSE") init-file-debug)
  "Whether verbose logging is enabled or not.")
(setq use-package-verbose IS-VERBOSE
      use-package-compute-statistics IS-VERBOSE)

;;;; Macros

(defmacro defhook! (name arglist hook &optional docstring &rest body)
  "Define a hook function called NAME and add it to HOOK.
NAME and ARGLIST are as in `defun'. HOOK is the hook to add the
function to. APPEND is whether to append to the hook or
not. DOCSTRING and BODY are as in `defun'.

For a version that removes itself from the hook after execution,
see `defhook-t!'."
  (declare (indent 3)
           (doc-string 4))
  (unless (string-match-p "-hook$" (symbol-name hook))
    (error "defhook!: symbol `%S' is not a hook" hook))
  `(progn
     (defun ,name ,arglist
       ,docstring
       ,@body)
     (add-hook ',hook #',name)))

(defmacro defhook-t! (name arglist hook &optional docstring &rest body)
  "Define a self-removing hook function called NAME and add it to HOOK.
NAME and ARGLIST are as in `defun'. HOOK is the hook to add the
function to. APPEND is whether to append to the hook or
not. DOCSTRING and BODY are as in `defun'.

For a version that is not transient, see `defhook!'."
  (declare (indent 3)
           (doc-string 4))
  (unless (string-match-p "-hook$" (symbol-name hook))
    (error "defhook!: symbol `%S' is not a hook" hook))
  `(progn
     (defun ,name ,arglist
       ,docstring
       ,@body
       (remove-hook ',hook #',name))
     (add-hook ',hook #',name)))

;; TODO: Silence messages from calls to `load'.
(defmacro quiet! (&rest forms)
  "Run FORMS without generating any minibuffer output."
  `(if IS-VERBOSE
       (progn ,@forms)
     (let ((inhibit-message t)
	         (save-silently t))
       (progn ,@forms))))

;;;; Hooks

(defvar my-startup-hook nil
  "Hook run at the start of `emacs-startup-hook'.")

(defun my//run-startup-hook ()
  "Run hook functions in `my-startup-hook'."
  (run-hooks 'my-startup-hook))
(add-hook 'emacs-startup-hook #'my//run-startup-hook)

;;;; Basics

;; Disable startup-related noise.
(setq
 ;; Disable the default init file (if it exists).
 inhibit-default-init t
 ;; Disable the startup buffer.
 ;; TODO: Create my own more useful startup screen buffer.
 inhibit-startup-message t
 ;; Disable the startup message. This requires the current username to disable
 ;; because Emacs is strange sometimes.
 inhibit-startup-echo-area-message user-login-name
 ;; Change the major mode for the *scratch* buffer to `fundamental-mode'. The
 ;; default is `lisp-interaction-mode', which causes `prog-mode-hook' (and thus
 ;; many packages) to be run immediately after init, effectively increasing our
 ;; time to interactivity.
 initial-major-mode #'fundamental-mode
 ;; Set the initial contents of the *scratch* buffer to be empty.
 initial-scratch-message nil)

;; Remove the Emacs information message on startup.
(fset #'display-startup-echo-area-message #'ignore)

;; Disable warnings from the legacy advice system. They are not useful, and
;; nothing can be done about them besides changing packages upstream.
(setq ad-redefinition-action 'accept)

;; Make apropos omnipotent. It is more useful this way.
(setq apropos-do-all t)

;; Make Emacs use Unicode and UTF-8 by default.
(set-charset-priority 'unicode)
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
;; The contents of the clipboard on Windows could be in an encoding that is
;; wider than UTF-8, so let Emacs/the OS decide what encoding to use.
(unless IS-WINDOWS (set-selection-coding-system 'utf-8))

;;;; Performance

;; Do not render cursors or regions in non-focused windows.
(setq-default cursor-in-non-selected-windows nil)
(setq highlight-nonselected-windows nil)

;; Do not make a second case-insensitive pass over `auto-mode-alist'.
(setq auto-mode-case-fold nil)

;; Do not ping things that look like domain names.
(setq ffap-machine-p-known 'reject)

;; so-long mitigates performance Emacs' performance issues with files that are
;; either large in size or line length.
(use-package so-long
  :defer t
  :init
  (defhook-t! my//enable-so-long-mode () find-file-hook
    "Enable `global-so-long-mode'."
    (global-so-long-mode 1)))

;;;; File System Cleanup

;; Emacs has an annoying habbit of littering files all everywhere. Luckily, with
;; the right incantations, Emacs can be taught otherwise.
;;
;; The first offender is the customisation system, which stores all
;; customisations at the bottom of init.el by default. Since I don't actually
;; use the customisation system, I set the custom file as a uniquely named file
;; in the system's temporary directory, in effect discarding it.

(setq custom-file (expand-file-name
                   (format "emacs/custom-%d-%d.el" (emacs-pid) (random))
                   temporary-file-directory))

;; The last two offenders, Emacs' backup and auto save systems, come hand in
;; hand. By default, backups and auto saves are created next to the relevant
;; files. To avoid having the file system littered with such files, I tell Emacs
;; to store them in the system's temporary directory, just like with to
;; customisations.
;;
;; TODO: Investigate possibly storing these somewhere less volatile.

(setq backup-directory-alist
      `((".*" . ,(expand-file-name "emacs" temporary-file-directory)))
      auto-save-list-file-prefix
      (expand-file-name "auto-save/sessions/" DATA-DIR)
      auto-save-file-name-transforms
      `((".*" ,(expand-file-name "emacs" temporary-file-directory) t)))

;;; Keybindings

;; My keybinding setup is inspired by Doom Emacs and, therefore, Spacemacs. Most
;; keybindings are centred around an easily accessible leader key (SPC by
;; default) and a secondary "local" leader key (SPC m by default) for commands
;; that pertain to either the current major mode or minor modes.

;;;; Setup

(defvar my-leader-key "SPC"
  "The leader key for global commands.")
(defvar my-alt-leader-key "M-SPC"
  "The leader key for global commands in insert and Emacs state.")
(defvar my-local-leader-key "SPC m"
  "The leader key for major mode-specific commands.")
(defvar my-local-alt-leader-key "M-SPC m"
  "The leader key for major mode-specific commands in insert and Emacs state.")

(defvar my-leader-map (make-sparse-keymap)
  "The keymap for leader keys.")
(defvar my-local-leader-map (make-sparse-keymap)
  "The keymap for leader keys.")

;; General is the package that does all the heavy lifting and makes everything
;; Just Work.
(use-package general
  :config
  (progn
    ;; Create some convenient definers for Evil, such as general-nmap
    ;; (which binds a key that is active in normal state).
    (general-evil-setup t)

    ;; Create a pair of custom definers for the leader and local
    ;; leader.
    (general-create-definer leader-def
      :states '(normal insert visual motion emacs)
      :prefix my-leader-key
      :non-normal-prefix my-alt-leader-key
      :prefix-map 'my-leader-map)
    (general-create-definer local-leader-def
      :states '(normal insert visual motion emacs)
      :prefix my-local-leader-key
      :non-normal-prefix my-local-alt-leader-key
      :prefix-map 'my-local-leader-map)))

;; Add a useful popup window that displays which keybindings are
;; reachable from the current key sequence.
(use-package which-key
  ;; :hook (my-startup . which-key-mode)
  :defer 1
  :init
  (progn
    (setq which-key-sort-order #'which-key-prefix-then-key-order
          which-key-sort-uppercase-first nil
          which-key-add-column-padding 1
          which-key-min-display-lines 6
          which-key-side-window-slot -10)

    (defhook-t! my//enable-which-key-mode () pre-command-hook
      "Enable `which-key-mode'."
      (which-key-mode 1)))
  :config
  (which-key-mode 1)
  (progn
    ;; Improve the readability of the pop up window.
    (defhook! my//set-which-key-line-spacing () which-key-init-buffer-hook
      "Set the line spacing for `which-key-mode'."
      (setq line-spacing 3))
    (set-face-attribute 'which-key-local-map-description-face nil :weight 'bold)))

;; With the setup out of the way, let's get to binding some basic keys!

;; Make the escape key, well, an escape key.
(define-key key-translation-map (kbd "ESC") (kbd "C-g"))

;; Make M-x more readily accessible.
(leader-def "SPC" '(execute-extended-command :wk "Execute Command"))

;; C-u is rebound for scrolling as in Vim, so this has to live
;; somewhere.
(leader-def "u" '(universal-argument :wk "Universal Argument"))

;; Give all of the prefixes a useful description.
(leader-def
  "f" '(nil :wk "File")
  "b" '(nil :wk "Buffer")
  "w" '(nil :wk "Window")
  "h" '(nil :wk "Help")
  "t" '(nil :wk "Toggles")
  "a" '(nil :wk "Applications"))

;;;; File

(leader-def "." '(find-file :wk "Open File"))
(leader-def "f f" '(find-file :wk "Open File"))
(leader-def "f i" '(insert-file :wk "Insert File after Point"))

;;;; Buffer

(defun my/alternate-buffer ()
  "Switch back and forth between the current and last buffer."
  (interactive)
  (switch-to-buffer (other-buffer)))

(defun my/kill-current-buffer (&optional arg)
  "Kill the current buffer.
If the universal prefix argument ARG is provided, also kill the
window."
  (interactive "P")
  (if (window-minibuffer-p)
      (abort-recursive-edit)
    (if (equal '(4) arg)
        (kill-buffer-and-window)
      (kill-buffer))))

(leader-def
  "TAB" '(my/alternate-buffer :wk "Switch to Last Buffer")
  "," '(switch-to-buffer :wk "Switch to Buffer")
  "b TAB" '(my/alternate-buffer :wk "Switch to Last Buffer")
  "b b" '(switch-to-buffer :wk "Switch to Buffer")
  "b k" '(my/kill-current-buffer :wk "Kill Current Buffer")
  "b K" '(kill-buffer :wk "Kill Buffer"))

;;;; Window

(defun my/alternate-window ()
  "Switch back and forth between the current and last window."
  (interactive)
  (let ((last-window (get-mru-window nil t t)))
    (unless last-window (user-error "Last window not found"))
    (select-window last-window)))

(defun my/delete-current-window (&optional arg)
  "Delete the current window.
If the universal prefix argument ARG is provided, also kill the
buffer."
  (interactive "P")
  (if (equal '(4) arg)
      (kill-buffer-and-window)
    (delete-window)))

(leader-def
  "w TAB" '(my/alternate-window :wk "Switch to Last Window")
  "w -" '(split-window-vertically :wk "Split Window Vertically")
  "w /" '(split-window-horizontally :wk "Split Window Horizontally")
  "w =" '(balance-windows-area :wk "Balance Windows")
  "w F" '(make-frame :wk "Create New Frame")
  "w k" '(my/delete-current-window :wk "Delete Current Window"))

;;;; Applications

(leader-def "a d" '(dired :wk "Browse Directory"))

;;;; Help

(leader-def
  "h a" '(apropos-command :wk "Apropos")
  "h i" '(info :wk "Browse Info Documentation")
  "h m" '(man :wk "Open Man Page")
  "h P" '(describe-package :wk "Describe Package")
  "h C" '(describe-coding-system :wk "Describe Coding System")
  "h n" '(view-emacs-news :wk "View Emacs News"))

;;; Visuals
;;;; Fonts

;; Tell Emacs to get my preferred font from FontConfig by setting the font to
;; 'monospace'.
(add-to-list 'default-frame-alist '(font . "monospace-10"))

;; Add the ability to display icon fonts.
(use-package all-the-icons :defer t)

;;;; Theme

;; TODO: Write my own Ayu theme to replace doom-one.
(use-package doom-themes
  :defer t
  :init
  (progn
    (defun my//set-theme ()
      "Set the theme."
      (require 'doom-themes)
      (load-theme 'doom-one t))
    (add-hook 'after-init-hook #'my//set-theme t)))

;;;; Modeline

;; TODO: Write my own custom modeline.
(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  ;; Disable the major mode icons since they are often misaligned and too small.
  :init (setq doom-modeline-major-mode-icon nil)
  :config
  (progn
    ;; Display the file size and column number in the modeline.
    (size-indication-mode 1)
    (column-number-mode 1)))

;;; Interface
;;;; Basics

(setq
 ;; Emacs defaults to using dialogue boxes in some cases, rather than a text
 ;; prompt. I disable this because it is annoying, especially when you use a
 ;; tiling window manager.
 use-dialog-box nil
 ;; By Emacs will not let you open another minibuffer while one is already open.
 ;; Since this behaviour is useful for certain patterns, I enable it.
 enable-recursive-minibuffers t
 ;; These two settings enable "focus follows mouse" behaviour, which makes Emacs
 ;; match how my window manager works (bspwm for the curious).
 focus-follows-mouse t
 mouse-autoselect-window t

 ;; Display the current file, directory, and hostname as the frame title.
 frame-title-format '(:eval
                      (format "%s@%s: %s %s"
                              (or (file-remote-p default-directory 'user)
                                  user-real-login-name)
                              (or (file-remote-p default-directory 'host)
                                  system-name)
                              (buffer-name)
                              (cond
                               (buffer-file-truename
                                (concat "(" buffer-file-truename ")"))
                               (dired-directory
                                (concat "{" dired-directory "}"))
                               (t "[no file]")))))

;; Disable GUI tooltips.
(tooltip-mode -1)

;; Typing yes/no is obnoxious when y/n will do.
(fset #'yes-or-no-p #'y-or-n-p)

;; Show current key sequence in the minibuffer after 0.05 seconds.
(setq echo-keystrokes 0.05)

;; Make scrolling less jumpy and jarring.
(setq scroll-conservatively 10000)

;;;; Window Configurations

;; Eyebrowse provides a simple way to manage configurations of windows.
;; TODO: Properly set this up.
(use-package eyebrowse :hook (my-startup . eyebrowse-mode))

;;;; Minibuffer Completion and Narrowing

(use-package prescient
  :defer t
  ;; Store the history in an XDG BaseDir-compliant location.
  :init (setq prescient-save-file
	            (expand-file-name "prescient-history.el" DATA-DIR))
  :config (prescient-persist-mode 1))

(use-package ivy
  :defer 2
  :init
  (progn
    (setq
     ;; Wrap around to the top when hitting the bottom of the candidates or vice
     ;; versa.
     ivy-wrap t
     ;; Keep the completion window at a constant height of 15 lines.
	   ivy-height 15
	   ivy-fixed-height-minibuffer t
     ;; Display the current candidate count and index.
	   ivy-count-format "(%d/%d) ")

    (defhook-t! my//enable-ivy-mode () pre-command-hook
      "Enable `ivy-mode'."
      (ivy-mode 1)))
  :config (ivy-mode 1))

(use-package counsel
  :hook (ivy-mode . counsel-mode)
  :general
  (leader-def
    "SPC" '(counsel-M-x :wk "Execute Command")
    "f r" '(counsel-recentf :wk "Open Recent File")
    "h f" '(counsel-describe-function :wk "Describe Callable")
    "h v" '(counsel-describe-variable :wk "Describe Variable")))

;; Swiper replaces isearch with a fancier Ivy-powered alternative.
(use-package swiper :general ([remap isearch-forward] #'swiper))

(use-package ivy-prescient
  :after (ivy counsel)
  :config (ivy-prescient-mode 1))

;;;; Recent Files

(use-package recentf
  :defer t
  :init
  (progn
    (setq recentf-max-menu-items 0
          recentf-max-saved-items 100
          ;; I replace this by instead cleaning the recents list when Emacs
          ;; exits.
          recentf-auto-cleanup 'never
          ;; Store the recents in an XDG BaseDir-compliant location.
          recentf-save-file (expand-file-name "recentf.el" DATA-DIR))

    ;; Defer loading recentf until a buffer is loaded from a file.
    (defhook-t! my//enable-recentf-mode () find-file-hook
      "Enable `recentf-mode'."
      (quiet! (recentf-mode 1))))
  :config (add-hook 'kill-emacs-hook #'recentf-cleanup))

;;;; Help

;; Replace the default help interface with something prettier and more, as the
;; name implies, helpful.
(use-package helpful
  :general
  ;; Remap the default C-h bindings.
  ([remap describe-key] #'helpful-key)
  ;; Add help bindings on the leader key.
  (leader-def
    "h k" '(helpful-key :wk "Describe Key")
    "h d" '(helpful-kill-buffers :wk "Kill Help Buffers"))
  :init
  ;; Tell Counsel to use Helpful's functions.
  (setq counsel-describe-function-function #'helpful-callable
	      counsel-describe-variable-function #'helpful-variable))

;;; Editing
;;;; Basics

 ;; Indentation
(setq-default tab-width 2
              indent-tabs-mode nil)

;; Line wrapping
(setq-default fill-column 80)
(setq sentence-end-double-space nil)
(add-hook 'text-mode-hook #'auto-fill-mode)

;; Highlight TODO and similar keywords in comments and strings.
(use-package hl-todo :hook (prog-mode . hl-todo-mode))

;; Automatically revert buffers whose backing files have been modified.
(global-auto-revert-mode 1)

;;;; Vim Emulation

(use-package undo-tree
  :defer t
  :init
  (setq
   ;; Display diffs by default in the visualiser.
   undo-tree-visualizer-diff t
   ;; Enable persistent undo history.
   undo-tree-auto-save-history t
   undo-tree-history-directory-alist
   `(("." . ,(expand-file-name "undo/" DATA-DIR)))))

;; Evil provides Vim emulation in a way that somehow manages to make Emacs a
;; better Vim than Vim itself.
(use-package evil
  :hook (my-startup . evil-mode)
  :init
  (progn
    (setq evil-want-C-u-scroll t
          ;; The default behaviour of Y in Vim is inconsistent anyway.
          evil-want-Y-yank-to-eol t
          evil-want-visual-char-semi-exclusive t
          evil-ex-search-vim-style-regexp t
          evil-ex-substitute-global t
          evil-ex-visual-char-range t
          evil-insert-skip-empty-lines t
          ;; Disable setting the mark with shift + motion keys.
          shift-select-mode nil)

    ;; This behaviour is closer to Vim.
    (setq-default evil-symbol-word-search t))
  :config
  (progn
    ;; Make Evil aware of the appropriate initial state for modes that it is not
    ;; aware of.
    (evil-set-initial-state #'messages-buffer-mode 'motion)
    (evil-set-initial-state #'helpful-mode 'motion)

    ;; I prefer the behaviour of `evil-search' over `isearch'.
    (evil-select-search-module 'evil-search-module #'evil-search)))

;; The following two packages provide features that are nearly essential in any
;; Vim-like editor: support for easily commenting/uncommenting code and managing
;; surrounding characters such as brackets.

(use-package evil-commentary
  :after evil
  :general
  (general-nmap
    "gc" #'evil-commentary
    "gy" #'evil-commentary-yank))

(use-package evil-surround
  :after evil
  :general
  (general-omap
    "s" #'evil-surround-edit
    "S" #'evil-Surround-edit)
  (general-vmap
    "S" #'evil-surround-region
    "gS" #'evil-Surround-region))

;;;; Line Numbers

;; TODO: Switch to absolute line numbers when the window and/or frame loses
;; focus.

;; I set up line numbers so that hybrid line numbers (relative + current line)
;; are used in normal state, and absolute numbers are used in insert state.

(setq-default
 ;; Display hybrid line numbers by default.
 display-line-numbers-type 'visual
 ;; Stop the line numbers from being "jumpy".
 display-line-numbers-width 3)

(defun my//turn-on-absolute-line-numbers ()
  "Turn on absolute line numbers for the current buffer."
  (setq display-line-numbers t))

(defun my//turn-on-hybrid-line-numbers ()
  "Turn on hybrid line numbers for the current buffer."
  (setq display-line-numbers 'visual))

(defun my/turn-on-line-numbers ()
  "Turn on line numbers for the current buffer.
The kind of line numbers depend on the current Evil state.  In
insert state, absolute line numbers are enabled.  In in all other
states, hybrid line numbers are enabled."
  (interactive)
  (display-line-numbers-mode 1)
  (add-hook 'evil-insert-state-entry-hook
	    #'my//turn-on-absolute-line-numbers nil t)
  (add-hook 'evil-insert-state-exit-hook
	    #'my//turn-on-hybrid-line-numbers nil t))

(defun my/turn-off-line-numbers ()
  "Turn off line numbers for the current buffer."
  (interactive)
  (display-line-numbers-mode -1)
  (remove-hook 'evil-insert-state-entry-hook
	       #'my//turn-on-absolute-line-numbers t)
  (remove-hook 'evil-insert-state-exit-hook
	       #'my//turn-on-hybrid-line-numbers t))

(defun my/toggle-line-numbers ()
  "Toggle line numbers for the current buffer.
For documentation on the type of line numbers used, see
  `my/turn-on-line-numbers'."
  (interactive)
  (if display-line-numbers
      (my/turn-off-line-numbers)
    (my/turn-on-line-numbers)))

(add-hook 'prog-mode-hook #'my/turn-on-line-numbers)

(leader-def "t n" '(my/toggle-line-numbers :wk "Toggle Line Numbering"))

;;;; Highlight Current Line

(use-package hl-line
  :hook ((text-mode prog-mode conf-mode) . hl-line-mode)
  :general (leader-def "t h" '(hl-line-mode :wk "Toggle Line Highlighting"))
  :init
  ;; Only highlight the line in the currently active buffer.
  (setq hl-line-sticky-flag nil
        global-hl-line-sticky-flag nil)
  :config
  (progn
    ;; Do not highlight the current line in visual or motion state.
    (defhook! my//enable-hl-line-mode () evil-visual-state-exit-hook
      "Enable `hl-line-mode'."
      (hl-line-mode 1))
    (defhook! my//disable-hl-line-mode () evil-visual-state-entry-hook
      "Disable `hl-line-mode'."
      (hl-line-mode 0))))

;;;; Fill Column Indicator

(use-package display-fill-column-indicator
  :hook ((text-mode prog-mode conf-mode) . display-fill-column-indicator-mode)
  :general (leader-def "t f" '(display-fill-column-indicator-mode
                               :wk "Toggle Fill Column")))

;;;; Bracket Pairing

;; TODO: Set this up properly.
(use-package smartparens
  :hook ((prog-mode . smartparens-mode)
         (prog-mode . show-smartparens-mode))
  :config
  (progn
    ;; Load the bundled language rules.
    (require 'smartparens-config)

    ;; Attempt to improve performance by reducing work on scanning for pairs.
    ;; (setq sp-max-prefix-length 25
    ;;       sp-max-pair-length 4)

    ;; Improve the behaviour of the pair overlays.
    ;; TODO: Remove the overlay when normal mode is entered.
    (setq sp-show-pair-from-inside t
          sp-cancel-autoskip-on-backward-movement nil)

    ;; Disable automatically escaping quotes until Fuco1/smartparens#783 is
    ;; fixed.
    (setq sp-escape-quotes-after-insert nil)

    ;; Silence messages about unmatched pairs.
    (dolist (key '(:unmatched-expression :no-matching-tag))
      (setf (alist-get key sp-message-alist) nil))))

;;;; Code Folding and Outlines

;; Outshine provides Org-like headings, outlines, and folding in any major
;; mode. In fact, it is what I use to help organise this very file.
(use-package outshine
  :hook (emacs-lisp-mode . outshine-mode))

;;;; Completion

(use-package company
  :hook (prog-mode . company-mode)
  :init
  (setq company-idle-delay 0.1
        company-minimum-prefix-length 1
        company-selection-wrap-around t
        company-tooltip-align-annotations t
        company-require-match 'never
        company-dabbrev-downcase nil
        company-dabbrev-ignore-case nil
        company-backends '(company-capf)
        company-frontends '(company-tng-frontend
                            company-pseudo-tooltip-frontend
                            company-echo-metadata-frontend))
  :config (company-tng-configure-default))

(use-package company-prescient
  :hook (company-mode . company-prescient-mode))

;;;; Checking

(use-package flycheck
  :hook ((emacs-lisp-mode haskell-mode lsp-mode) . flycheck-mode)
  :init
  ;; Disable automatically checking after a newline is inserted. This should
  ;; make Emacs feel snappier.
  (setq flycheck-check-syntax-automatically '(save idle-change mode-enabled))
  :config
  (with-eval-after-load 'evil
    ;; Check the buffer when entering normal state.
    (defhook! my//flycheck-buffer () evil-normal-state-entry-hook
      "Check the current buffer with Flycheck if enabled."
      (when flycheck-mode
        (ignore-errors (flycheck-buffer)) nil))

    ;; Increase responsiveness by increasing the idle time to a higher value in
    ;; insert state.
    (defhook! my//flycheck-slower () evil-insert-state-entry-hook
      "Set `flycheck-idle-change-delay' to a higher value."
      (when flycheck-mode
        (setq flycheck-idle-change-delay 1.5)))

    (defhook! my//flycheck-faster () evil-insert-state-exit-hook
      "Set `flycheck-idle-change-delay' back to default."
      (when flycheck-mode
        (setq flycheck-idle-change-delay (default-value 'flycheck-idle-change-delay))))))

;; TODO: Evaluate replacing this with flycheck-posframe.
(use-package flycheck-inline :hook (flycheck-mode . flycheck-inline-mode))

;;;; EditorConfig

;; EditorConfig enables cross-editor, per-project settings for things such as
;; indentation and line endings. Essentially, when used properly, it frees me up
;; from worrying about such things.

(use-package editorconfig
  :defer t
  :init
  (defhook-t! my//enable-editorconfig-mode () find-file-hook
    "Enable `editorconfig-mode'."
    (editorconfig-mode 1)))

;;; Language Support
;;;; Lisp

;; The packages Lispy and Lispyville are, in my opinion, the ultimate pairing
;; for editing Lisp. Lispy provides a Vim-inspired way of writing Lisp for
;; vanilla Emacs, and Lispyville integrates this into Evil.

(use-package lispy
  :hook ((emacs-lisp-mode lisp-mode scheme-mode) . lispy-mode)
  :init
  (progn
    ;; Move past the end quote of a string instead of escaping the quote when
    ;; pressing ".
    (setq lispy-close-quotes-at-end-p t)

    ;; Since Lispy covers Smartparens' functionality, disable it when Lispy is
    ;; active.
    (add-hook 'lispy-mode-hook #'turn-off-smartparens-mode)

    (defhook! my//enable-lispy-mode-for-eval () minibuffer-setup-hook
      "Enable `lispy-mode' when `eval-expression' is called in the minibuffer."
      (when (eq this-command #'eval-expression)
        (lispy-mode 1)))))

(use-package lispyville
  :hook (lispy-mode . lispyville-mode)
  :config
  (progn
    (lispyville-set-key-theme
     '((operators normal)
       c-w
       (prettify insert)
       (atom-movement normal visual)
       slurp/barf-lispy
       (wrap normal insert)
       additional
       additional-insert
       commentary
       (additional-wrap normal insert)
       (escape insert)))

    ;; Automatically enter visual state when using Lispy's mark commands.
    (lispyville-enter-visual-when-marking)))

;; Colour pairs of delimiters according to their depth to make reading Lisp
;; easier.
(use-package rainbow-delimiters
  :hook ((emacs-lisp-mode lisp-mode scheme-mode) . rainbow-delimiters-mode))

;;;; Haskell

(use-package haskell-mode :defer t)

;; TODO: Enable after I set up Flycheck.
;; (use-package dante :hook (haskell-mode . dante-mode))

;;; Source Control

(use-package transient
  :defer t
  ;; Store the history in an XDG BaseDir-compliant location.
  :init (setq transient-history-file
	            (expand-file-name "transient-history.el" DATA-DIR)))

(use-package magit
  :general (leader-def "a g" '(magit-status :wk "Git Status"))
  :init
  (setq
   ;; I use `global-auto-revert-mode' instead.
   magit-auto-revert-mode nil
   ;; Magit replaces this.
   vc-handled-backends (delq 'Git vc-handled-backends)))

(use-package evil-magit
  :after magit
  :config (require 'evil-magit))

;; Add the ability to interact with Git "forges" (e.g. GitHub or Gitlab).
(use-package forge
  :after magit
  ;; Store the database in an XDG BaseDir-compliant location.
  :init (setq forge-database-file
              (expand-file-name "forge-database.sqlite" DATA-DIR)))

;; Modes for Git-related files such as .gitignore or .gitattributes.
(use-package git-modes :defer t)

;; TODO: Enable git-gutter-mode for more than code.
(if (display-graphic-p)
    (use-package git-gutter-fringe :hook (prog-mode . git-gutter-mode))
  (use-package git-gutter :hook (prog-mode . git-gutter-mode)))

;;; Applications
;;;; Org Mode

(use-package org
  :defer t
  :straight org-plus-contrib
  :init (setq org-default-notes-file "~/Documents/Notes/notes.org"
              org-agenda-files '("~/Documents/Notes/todo.org")
              ;; Highlight LaTeX syntax in Org files.
              org-highlight-latex-and-related '(native))
  :config
  (progn
    ;; Use LuaTeX for LaTeX previews.
    (add-to-list
     'org-preview-latex-process-alist
     '(luamagick
       :programs ("lualatex" "convert")
       :description "pdf > png"
       :message "you need to install the programs: lualatex and imagemagick."
       :use-xcolor t
       :image-input-type "pdf"
       :image-output-type "png"
       :image-size-adjust (1.0 . 1.0)
       :latex-compiler
       ("lualatex -interaction nonstopmode -output-directory %o %f")
       :image-converter
       ("convert -density %D -trim -antialias %f -quality 100 %O")))

    (setq org-preview-latex-default-process 'luamagick)
    (setq org-format-latex-options
          '(:foreground default
            :background "#282c34"
            :scale 1.5
            :html-foreground "Black"
            :html-background "Transparent"
            :html-scale 1.0
            :matchers ("begin" "$1" "$" "$$" "\\(" "\\[")))))

(use-package ox-latex
  :defer t
  :straight org-plus-contrib
  :init
  ;; Use LuaTeX as the TeX engine and modernise the default packages
  ;; accordingly.
  (setq org-latex-compiler "lualatex"
        ;; TODO: Make sure that all packages required by Org are here.
        org-latex-default-packages-alist
        '(("" "fontspec" t)
          ("" "graphicx" t)
          ("" "url" nil)
          ("" "rotating" nil)
          ("hidelinks" "hyperref" nil)
          ("english=british" "csquotes" nil)
          ("" "mathtools" t)
          ("" "siunitx" t)
          ("" "unicode-math" t)))
  :config
  (progn
    ;; Use KomaScript's version of article as the default document class.
    (add-to-list
     'org-latex-classes
     '("koma-article" "\\documentclass[headings=standardclasses]{scrartcl}"
       ("\\section{%s}" . "\\section*{%s}")
       ("\\subsection{%s}" . "\\subsection*{%s}")
       ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
       ("\\paragraph{%s}" . "\\paragraph*{%s}")
       ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))
    (setq org-latex-default-class "koma-article")))

;; Make the heading bullets prettier.
(use-package org-bullets :hook (org-mode . org-bullets-mode))
