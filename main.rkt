#lang racket/base

(require racket/contract)

(provide
 (rename-out [xdg-program-name current-xdg-program-name])
 (contract-out
  [list-config-files (-> path-string? path-string? (listof path?))]
  [list-data-files (-> path-string? path-string? (listof path?))]
  [list-cache-files (-> path-string? path-string? (listof path?))]
  [writable-config-file (-> path-string? path-string? path?)]
  [writable-data-file (-> path-string? path-string? path?)]
  [writable-cache-file (-> path-string? path-string? path?)]
  ))

(define unixy-os? (not (equal? (system-type 'os) 'windows)))

#|
Windows paths to use:
%HOMEPATH% = C:\Users\(user-name)
%LOCALAPPDATA% = C:\Users\(user-name)\AppData\Local
%APPDATA% = C:\Users\(user-name)\AppData\Roaming
%TEMP% = C:\Users\(user-name)\AppData\Local\Temp

I am assured that all of these Windows environment variables should
always exist.  And $HOME should always be there on any unix system.
|#

(define (data-home)
  (define (default)
    (if unixy-os?
        (string-append (getenv "HOME") "/.local/share/")
        (getenv "APPDATA")))
  (or (getenv "XDG_DATA_HOME") (default)))
(define (data-dirs)
  (define (default)
    (if unixy-os?
        "/usr/local/share/:/usr/share/"
        (getenv "APPDATA")))
  (or (getenv "XDG_DATA_DIRS") (default)))
(define (config-home)
  (define (default)
    (if unixy-os?
        (string-append (getenv "HOME") "/.config/")
        (getenv "LOCALAPPDATA")))
  (or (getenv "XDG_CONFIG_HOME") (default)))
(define (config-dirs)
  (define (default)
    (if unixy-os?
        "/etc/xdg"
        (getenv "APPDATA")))
  (or (getenv "XDG_CONFIG_DIRS") (default)))
(define (cache-home)
  (define (default)
    (if unixy-os?
        (string-append (getenv "HOME") "/.cache/")
        (getenv "TEMP")))
  (or (getenv "XDG_CACHE_HOME") (default)))
;; TODO - runtime-dir

(define xdg-program-name (make-parameter "unnamed-program"))

(define (make-xdg-path base program file)
  (cleanse-path (expand-user-path (build-path base program file))))
(define (xdg-path-if-exists base program file)
  (let ([path (make-xdg-path base program file)])
    (if (file-exists? path)
        path
        #f)))

(define (list-files dirs-string home-dir-string file-name program-name)
  (let* ([dirs (path-list-string->path-list (dirs-string))]
         [paths (cons (make-xdg-path home-dir-string program-name file-name)
                      (map (λ (d) (build-path d program-name file-name))
                           dirs))]
         [clean-paths (map cleanse-path (map expand-user-path paths))])
    (filter file-exists? clean-paths)))

(define (list-data-files file-name [program-name (xdg-program-name)])
  (list-files (data-dirs) (data-home) file-name program-name))
(define (list-config-files file-name [program-name (xdg-program-name)])
  (list-files (config-dirs) (config-home) file-name program-name))
(define (list-cache-files file-name [program-name (xdg-program-name)])
  (filter (λ (x) x) (list (xdg-path-if-exists (cache-home) program-name file-name))))

(define (writable-config-file file-name [program-name (xdg-program-name)])
  (build-path (config-home) program-name file-name))
(define (writable-data-file file-name [program-name (xdg-program-name)])
  (build-path (data-home) program-name file-name))
(define (writable-cache-file file-name [program-name (xdg-program-name)])
  (build-path (cache-home) program-name file-name))




