#lang racket/base

(require racket/contract)

(provide
 (rename-out [xdg-program-name current-xdg-program-name])
 (contract-out
  [list-config-files (->* (path-string?) (path-string?) (listof path?))]
  [list-data-files (->* (path-string?) (path-string?) (listof path?))]
  [list-cache-files (->* (path-string?) (path-string?) (listof path?))]

  [list-config-dirs (->* () (path-string?) (listof path?))]
  [list-data-dirs (->* () (path-string?) (listof path?))]
  [list-cache-dirs (->* () (path-string?) (listof path?))]

  [writable-config-file (->* (path-string?) (path-string?) path?)]
  [writable-data-file (->* (path-string?) (path-string?) path?)]
  [writable-cache-file (->* (path-string?) (path-string?) path?)]

  [writable-config-dir (->* () (path-string?) path?)]
  [writable-data-dir (->* () (path-string?) path?)]
  [writable-cache-dir (->* () (path-string?) path?)]
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
(define (cache-dirs) "")
;; TODO - runtime-dir

(define xdg-program-name (make-parameter "unnamed-program"))

(define (cpath path)
  (cleanse-path (expand-user-path path)))

(define (make-xdg-dir-path base program)
  (cpath (build-path base program)))
(define (make-xdg-file-path base program file)
  (cpath (build-path (make-xdg-dir-path base program) file)))
(define (make-xdg-file-path* dir-path file)
  (cpath (build-path dir-path file)))

(define (list-dirs dirs-string home-dir-string program-name)
  (let ([dirs (path-list-string->path-list dirs-string null)])
    (cons (make-xdg-dir-path home-dir-string program-name)
          (map (λ (d) (make-xdg-dir-path d program-name)) dirs))))

(define (list-files dirs-string home-dir-string file-name program-name)
  (let ([dirs (list-dirs dirs-string home-dir-string program-name)])
    (filter file-exists? (map (λ (d) (make-xdg-file-path* d file-name)) dirs))))

;;;;;;;;;;;; The exported functions

(define (list-data-files file-name [program-name (xdg-program-name)])
  (list-files (data-dirs) (data-home) file-name program-name))
(define (list-config-files file-name [program-name (xdg-program-name)])
  (list-files (config-dirs) (config-home) file-name program-name))
(define (list-cache-files file-name [program-name (xdg-program-name)])
  (list-files (cache-dirs) (cache-home) file-name program-name))

(define (list-data-dirs [program-name (xdg-program-name)])
  (list-dirs (data-dirs) (data-home) program-name))
(define (list-config-dirs [program-name (xdg-program-name)])
  (list-dirs (config-dirs) (config-home) program-name))
(define (list-cache-dirs [program-name (xdg-program-name)])
  (list-dirs (cache-dirs) (cache-home) program-name))

(define (writable-data-file file-name [program-name (xdg-program-name)])
  (build-path (data-home) program-name file-name))
(define (writable-config-file file-name [program-name (xdg-program-name)])
  (build-path (config-home) program-name file-name))
(define (writable-cache-file file-name [program-name (xdg-program-name)])
  (build-path (cache-home) program-name file-name))

(define (writable-data-dir [program-name (xdg-program-name)])
  (build-path (data-home) program-name))
(define (writable-config-dir [program-name (xdg-program-name)])
  (build-path (config-home) program-name))
(define (writable-cache-dir [program-name (xdg-program-name)])
  (build-path (cache-home) program-name))




