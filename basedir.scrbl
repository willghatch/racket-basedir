#lang scribble/manual
@(require (for-label racket/base
                     racket/contract
                     basedir))

@title[#:tag "basedir"]{XDG Basedir Library}
@author+email["William Hatch" "william@hatch.uno"]

@defmodule[basedir]

@section{XDG Basedir Specification}

This library provides functions for easily accessing configuration and
data files according to the @deftech{XDG Base Directory
Specification}.

The point of the XDG base directory is to allow programs to put
configuration and data files on the filesystem in a consistent and
user-configurable way.  It solves the problem of having many different
configuration and data files and directories (dotfiles) in your home
directory.

An important point of the XDG specification is that it specifies a
single directory for writable configuration files
(@code{$XDG_CONFIG_HOME}) and a list of directories
(@code{$XDG_CONFIG_DIRS}) for non-writable configuration files.  If a
program can modify its own configuration, it should do so only using
the writable directory, and not change the others.  Similarly
@code{$XDG_DATA_HOME} and @code{$XDG_DATA_DIRS} exist for the same
purpose for data files.  There is only one directory for cache files
(@code{$XDG_CACHE_HOME}), since the whole point of cache files is that
they are for the program to write.

Having multiple configuration or data file directories is useful.
Consider the common scenario of keeping a synchronized directory
of configuration data (with git, dropbox, or the like), as well as
local configuration for each machine, and potentially different
directories for public and private synchronized configuration.
So programs should read all available configuration files and
compose the configurations, where possible.

When unset, the XDG variables default to:
@itemlist[
@item{@code{$XDG_CONFIG_HOME} = @code{$HOME/.config/} (on Windows: @code{%LOCALAPPDATA%})}
@item{@code{$XDG_CONFIG_DIRS} = @code{/etc/xdg/} (on Windows: @code{%APPDATA%})}
@item{@code{$XDG_DATA_HOME} = @code{$HOME/.local/share/} (on Windows: @code{%LOCALAPPDATA%})}
@item{@code{$XDG_DATA_DIRS} = @code{/usr/local/share/:/usr/share/} (on Windows: @code{%APPDATA%})}
@item{@code{$XDG_CACHE_HOME} = @code{$HOME/.cache} (on Windows: @code{%TEMP%})}
@item{@code{$XDG_RUNTIME_DIR} is a little more complicated.  On Unixy
systems it checks whether @code{/run/user/$(id -u)} exists and uses it
if it does (systems with systemd and its PAM module have these
directories created automatically for this purpose).  Otherwise it
falls back to @code{/tmp/user-$USER}.  On Windows it currently
defaults to @code{%TEMP%}, because I am unaware of a standard
directory with semantics more like @code{XDG_RUNTIME_DIR} is supposed
to have.}
]

Some words of warning about the runtime dir: The runtime dir should be
used for storing ephemeral things like pipes and sockets or other
objects restricted to the current run of the program.  It is likely
created when a user logs in and deleted when the user logs out.  It
probably lives in a RAM-based file system.  The spec says that it may
be cleaned of old files occasionally, and to keep your files from
being cleaned up you should either update their timestamps regularly
(every 6 hours is what they consider regularly) or set the sticky bit
on the files.  The directory should be readable only by the owner.

To learn more about the XDG basedir specification, visit
@url{https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html}

@section{Reference}

@defparam[current-basedir-program-name name path-string?]{
Default program name for making file-system paths in the
configuration, data, etc directories.  For the love of all
that is good, please do not put spaces in this.

This parameter is provided for convenience, so that you
can set your program's XDG path name once and not put it
in every call to other basedir functions.

The default value of this parameter is NOT guaranteed to remain
stable.  A program that wants to have configuration files should be
setting its name so the user can see it.
}

@deftogether[(
@defproc[(list-config-files [file-name path-string?]
                            [#:program program-name path-string? (current-basedir-program-name)]
                            [#:only-existing? only-existing? any/c #t])
         (listof path?)]{}
@defproc[(list-data-files [file-name path-string?]
                          [#:program program-name path-string? (current-basedir-program-name)]
                          [#:only-existing? only-existing? any/c #t])
         (listof path?)]{}
@defproc[(list-cache-files [file-name path-string?]
                           [#:program program-name path-string? (current-basedir-program-name)]
                           [#:only-existing? only-existing? any/c #t])
         (listof path?)]{}
@defproc[(list-runtime-files [file-name path-string?]
                           [#:program program-name path-string? (current-basedir-program-name)]
                           [#:only-existing? only-existing? any/c #t])
         (listof path?)]{}
)]{
Returns a list of configuration (or data or cache) files with the name
@racket[file-name].  If @racket[only-existing?] is true, then only files
that actually exist on the file system will be returned.

For example, let's say you write a program named "foo" and your main config file
is named "foorc".
Bobby (a Debian user) has @code{$XDG_CONFIG_HOME} unset (IE at its
default value) and @code{$XDG_CONFIG_DIRS} set to
@code{/home/bobby/config-git:/home/bobby/config-git-private:/home/bobby/local-config}
and the files @code{/home/bobby/.config/foo/foorc},
@code{/home/bobby/config-git/foo/foorc}, and
@code{/home/bobby/local-config/foo/foorc} exist (but not
@code{/home/bobby/config-git-private/foo/foorc}), then
@code{(list-config-files "foorc" #:program "foo")} will return a list of paths
for those three files that exist on the path.  The @code{foo} program
should, if possible, use the pieces of configuration found in each of
the files.

Also note that @racket[file-name] may actually be a path
(eg. @code{subdir/filename}), in case you want further nesting in your
configuration or data directory.

Since there is only one cache directory and one runtime directory,
@racket[list-cache-files] and @racket[list-runtime-files] will return
either a list with one element or an empty list.
}

@deftogether[(
@defproc[(writable-config-file [file-name path-string?]
                               [#:program program-name path-string? (current-basedir-program-name)])
         path?]

@defproc[(writable-data-file [file-name path-string?]
                             [#:program program-name path-string? (current-basedir-program-name)])
         path?]
@defproc[(writable-cache-file [file-name path-string?]
                              [#:program program-name path-string? (current-basedir-program-name)])
         path?]
@defproc[(writable-runtime-file [file-name path-string?]
                              [#:program program-name path-string? (current-basedir-program-name)])
         path?]
)]{
Returns a path to the writable configuration/data/cache file with the
name @racket[file-name].  The file or directory to the file may not
exist (so you may want to @racket[make-parent-directory*] on it and
set any relevent permissions), and permissions may not make it
actually writable (IE @racket[make-directory] may fail), but the path
is in the user-configured (or default) directory for writable
configuration/data/etc files.

Following the example from above with Bobby and the foo program,
while several "foorc" files exist, the only one that should be written
to is @code{/home/bobby/.config/foo/foorc}.  That path would be returned
by @code{(writable-config-file "foorc" #:program "foo")}
}

@deftogether[(
@defproc[(list-config-dirs [#:program program-name path-string? (current-basedir-program-name)]
                           [#:only-existing? only-existing? any/c #t])
         (listof path?)]
@defproc[(list-data-dirs [#:program program-name path-string? (current-basedir-program-name)]
                         [#:only-existing? only-existing? any/c #t])
         (listof path?)]
@defproc[(list-cache-dirs [#:program program-name path-string? (current-basedir-program-name)]
                          [#:only-existing? only-existing? any/c #t])
         (listof path?)]
@defproc[(list-runtime-dirs [#:program program-name path-string? (current-basedir-program-name)]
                          [#:only-existing? only-existing? any/c #t])
         (listof path?)]
)]{
Returns a list of paths to configuration/data/cache directories for
your program.  If @racket[only-existing?] is true, then only
directories that exist in the filesystem will be returned.  If there
is a particular file you are looking for in these directories, prefer
@racket[list-config-files] and friends.
}

@deftogether[(
@defproc[(writable-config-dir [#:program program-name path-string? (current-basedir-program-name)])
         path?]
@defproc[(writable-data-dir [#:program program-name path-string? (current-basedir-program-name)])
         path?]
@defproc[(writable-cache-dir [#:program program-name path-string? (current-basedir-program-name)])
         path?]
@defproc[(writable-runtime-dir [#:program program-name path-string? (current-basedir-program-name)])
         path?]
)]{
Returns the path to the writable configuration/data/cache directory for your
program.  Not guaranteed to exist.  If there is a particular configuration
file you want to write, prefer @racket[writable-config-file] and friends.
}

@section{Code and License}

The code is available
@hyperlink["https://github.com/willghatch/racket-basedir"]{on github}.

This library is distributed under the MIT license and the Apache version 2.0 license, at your option.

