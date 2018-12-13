#lang racket/base

(require
 racket/contract
 racket/string
 racket/port
 racket/system
 racket/list
 )

(provide
 (rename-out [xdg-program-name current-basedir-program-name])
 (contract-out
  [list-config-files (->* (path-string?)
                          (#:program path-string?
                           #:only-existing? any/c)
                          (listof path?))]
  [list-data-files (->* (path-string?)
                          (#:program path-string?
                           #:only-existing? any/c)
                          (listof path?))]
  [list-cache-files (->* (path-string?)
                          (#:program path-string?
                           #:only-existing? any/c)
                          (listof path?))]
  [list-runtime-files (->* (path-string?)
                          (#:program path-string?
                           #:only-existing? any/c)
                          (listof path?))]

  [list-config-dirs (->* ()
                         (#:program path-string?
                          #:only-existing? any/c)
                         (listof path?))]
  [list-data-dirs (->* ()
                         (#:program path-string?
                          #:only-existing? any/c)
                         (listof path?))]
  [list-cache-dirs (->* ()
                         (#:program path-string?
                          #:only-existing? any/c)
                         (listof path?))]
  [list-runtime-dirs (->* ()
                         (#:program path-string?
                          #:only-existing? any/c)
                         (listof path?))]

  [writable-config-file (->* (path-string?) (#:program path-string?) path?)]
  [writable-data-file (->* (path-string?) (#:program path-string?) path?)]
  [writable-cache-file (->* (path-string?) (#:program path-string?) path?)]
  [writable-runtime-file (->* (path-string?) (#:program path-string?) path?)]

  [writable-config-dir (->* () (#:program path-string?) path?)]
  [writable-data-dir (->* () (#:program path-string?) path?)]
  [writable-cache-dir (->* () (#:program path-string?) path?)]
  [writable-runtime-dir (->* () (#:program path-string?) path?)]
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
        (getenv "LOCALAPPDATA")))
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

(define (runtime-home)
  (define (default)
    (if unixy-os?
        (get-unix-default-runtime-dir)
        ;; I'm not sure what to do for Windows, except to re-use the TEMP dir.
        (getenv "TEMP")))
  (or (getenv "XDG_RUNTIME_DIR") (default)))
(define (get-unix-default-runtime-dir)
  (define (get-uid)
    ;; TODO - I feel like there should be a better way...
    (with-handlers ([(λ _ #t) (λ _ #f)])
      (string->number
       (string-trim
        (with-output-to-string
          (λ () (system* (find-executable-path "id") "-u")))))))
  (let* ([uid (get-uid)]
         [systemd-default-path (and uid (build-path "/run/user/"
                                                    (number->string uid)))]
         [username (getenv "USER")])
    (cond
      [(and systemd-default-path (directory-exists? systemd-default-path))
       systemd-default-path]
      ;; TODO - I want the next fallback to be /tmp/$USER or something, but I
      ;; want to check that it is actually owned by that user, and then set
      ;; the right permissions on it.  I'm not currently sure how to check the
      ;; ownership...
      ;; TODO - which of these should I actually prefer?
      [username (build-path "/tmp/" (string-append "user-" username))]
      [uid (build-path "/tmp/" (string-append "user-" (number->string uid)))]
      [else (build-path "/tmp")])))

(define xdg-program-name (make-parameter "unnamed-program"))

(define (cpath path)
  (cleanse-path (expand-user-path path)))

(define (make-xdg-dir-path base program)
  (cpath (build-path base program)))
(define (make-xdg-file-path base program file)
  (cpath (build-path (make-xdg-dir-path base program) file)))
(define (make-xdg-file-path* dir-path file)
  (cpath (build-path dir-path file)))

(define (list-dirs dirs-string home-dir-string program-name only-exist??)
  (let* ([dirs (path-list-string->path-list dirs-string null)]
         [paths (remove-duplicates
                 (cons (make-xdg-dir-path home-dir-string program-name)
                       (map (λ (d) (make-xdg-dir-path d program-name)) dirs)))])
    (if only-exist??
        (filter directory-exists? paths)
        paths)))

(define (list-files dirs-string home-dir-string file-name program-name only-exist??)
  (let* ([dirs (list-dirs dirs-string home-dir-string program-name #f)]
         [paths (map (λ (d) (make-xdg-file-path* d file-name)) dirs)])
    (if only-exist??
        (filter file-exists? paths)
        paths)))

;;;;;;;;;;;; The exported functions

;; TODO - use a macro (I wrote one with syntax-case that failed (begin
;; had no expression after sequence of definitions...))
(define (list-data-files file-name
                         #:program [program-name (xdg-program-name)]
                         #:only-existing? [only-existing? #t])
  (list-files (data-dirs) (data-home) file-name program-name only-existing?))
(define (list-config-files file-name
                         #:program [program-name (xdg-program-name)]
                         #:only-existing? [only-existing? #t])
  (list-files (config-dirs) (config-home) file-name program-name only-existing?))
(define (list-cache-files file-name
                         #:program [program-name (xdg-program-name)]
                         #:only-existing? [only-existing? #t])
  (list-files "" (cache-home) file-name program-name only-existing?))
(define (list-runtime-files file-name
                         #:program [program-name (xdg-program-name)]
                         #:only-existing? [only-existing? #t])
  (list-files "" (runtime-home) file-name program-name only-existing?))


(define (list-data-dirs
         #:program [program-name (xdg-program-name)]
         #:only-existing? [only-existing? #t])
  (list-dirs (data-dirs) (data-home) program-name only-existing?))
(define (list-config-dirs
         #:program [program-name (xdg-program-name)]
         #:only-existing? [only-existing? #t])
  (list-dirs (config-dirs) (config-home) program-name only-existing?))
(define (list-cache-dirs
         #:program [program-name (xdg-program-name)]
         #:only-existing? [only-existing? #t])
  (list-dirs "" (cache-home) program-name only-existing?))
(define (list-runtime-dirs
         #:program [program-name (xdg-program-name)]
         #:only-existing? [only-existing? #t])
  (list-dirs "" (runtime-home) program-name only-existing?))


(define (writable-data-file file-name #:program [program-name (xdg-program-name)])
  (build-path (data-home) program-name file-name))
(define (writable-config-file file-name #:program [program-name (xdg-program-name)])
  (build-path (config-home) program-name file-name))
(define (writable-cache-file file-name #:program [program-name (xdg-program-name)])
  (build-path (cache-home) program-name file-name))
(define (writable-runtime-file file-name #:program [program-name (xdg-program-name)])
  (build-path (runtime-home) program-name file-name))


(define (writable-data-dir #:program [program-name (xdg-program-name)])
  (build-path (data-home) program-name))
(define (writable-config-dir #:program [program-name (xdg-program-name)])
  (build-path (config-home) program-name))
(define (writable-cache-dir #:program [program-name (xdg-program-name)])
  (build-path (cache-home) program-name))
(define (writable-runtime-dir #:program [program-name (xdg-program-name)])
  (build-path (runtime-home) program-name))

