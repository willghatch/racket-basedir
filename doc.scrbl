#lang scribble/manual
@(require (for-label racket/base
                     racket/contract
                     xdg))

@title[#:tag "xdg"]{XDG Basedir Library}
@author+email["William Hatch" "william@hatch.uno"]

@defmodule[xdg]

This library provides functions for easily accessing configuration and
data files according to the @deftech{XDG Base Directory
Specification}.

The point of the XDG directory is to allow programs to put
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
]

@defparam[current-xdg-program-name name path-string?]{
Default program name for making file-system paths in the
configuration, data, etc directories.  For the love of all
that is good, please do not put spaces in this.

This parameter is provided for convenience, so that you
can set your program's XDG path name once and not put it
in every call to other XDG functions.
}

@defproc[(list-config-files [file-name path-string?]
                            [program-name path-string? (current-xdg-program-name)])
         (listof path?)]{
Returns a list of configuration files with the name
@racket[file-name].  All returned files actually exist on the file
system.

For example, let's say you write a program named "foo" and your main config file
is named "foorc".
Bobby (a Debian user) has @code{$XDG_CONFIG_HOME} unset (IE at its
default value) and @code{$XDG_CONFIG_DIRS} set to
@code{/home/bobby/config-git:/home/bobby/config-git-private:/home/bobby/local-config}
and @code{/home/bobby/.config/foo/foorc},
@code{/home/bobby/config-git/foo/foorc}, and
@code{/home/bobby/local-config/foo/foorc} exist (but not
@code{/home/bobby/config-git-private/foo/foorc}), then
@code{(list-config-files "foorc" "foo")} will return a list of paths
for those three files that exist on the path.  The @code{foo} program
should, if possible, use the pieces of configuration found in each of
the files.
}

@defproc[(list-data-files [file-name path-string?]
                          [program-name path-string? (current-xdg-program-name)])
         (listof path?)]{
Similar to @racket[list-config-files].
}

@defproc[(list-cache-files [file-name path-string?]
                           [program-name path-string? (current-xdg-program-name)])
         (listof path?)]{
Similar to @racket[list-config-files].

While it is a list to have the same interface as the other two, there
is only one cache directory defined by XDG, so the list will either have
one element or it will be empty.
}

@defproc[(writable-config-file [file-name path-string?]
                               [program-name path-string? (current-xdg-program-name)])
         path?]{
Returns a path to the writable configuration file with the name
@racket[file-name].  The file or directory to the file may not exist,
and permissions may not make it actually writable, but the path is in
the user-configured (or default) directory for writable configuration
files.

Following the example from above with Bobby and the foo program,
while several "foorc" files exist, the only one that should be written
to is @code{/home/bobby/.config/foo/foorc}.  That path would be returned
by @code{(writable-config-file "foorc" "foo")}
}

@defproc[(writable-data-file [file-name path-string?]
                             [program-name path-string? (current-xdg-program-name)])
         path?]{
Similar to @racket[writable-config-file].
}
@defproc[(writable-cache-file [file-name path-string?]
                              [program-name path-string? (current-xdg-program-name)])
         path?]{
Similar to @racket[writable-config-file].
}
