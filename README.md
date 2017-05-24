
Requirements
------------
* Ruby 2.1+ with RubyGems
* libxml2-dev and libxslt1-dev package is required to compile the 'nokogiri' gem.
* FreeTDS 0.9.x or later is required to compile the required gem 'tiny_tds'.
  If not available via system package manager, download the latest and most stable 0.9.x branch and compile. Configure with: ./configure --enable-msdblib.
  FreeTDS 0.8.x will not work. Note, libsybdb5 is required at runtime by tiny_tds.
  ** For development on OS X using homebrew, install using `brew install freetds --with-msdblib`
* imagemagick is required for thumbnail generation (e.g. zypper install imagemagick or brew install imagemagick)
* ghostscript is recommended for pdf thumbnails (e.g. zypper install ghostscript or brew install ghostscript)

Installation
------------
1) Get a copy of the files by either copying and pasting, or pushing/pulling from git.
2) `cd` into directory.
3) ```gem install bundler
4) ```bundle install
5) Copy app/config.default.yml to app/config.yml, and complete configuration.
6) Run with `rackup` or any Rack compatible web server (i.e. Phusion Passenger)

Migrations
----------
SQL migrations are located in the root of the application in the /db directory. These are automatically applied on startup.
To run manually, use the *sequel* command line tool. As an example:

```sequel -m /db "tinytds://server.domain.local/database?username=username&password=password"

Note, if the username or password contain special characters that invalidate the URI, such as a backslash, you must URI
encode them, so for example, the backslash would become %5C.

Mail
----
Sendmail (or something sendmail-compatible) is required for email capability, such as notifications. If it's not
installed, attempts to email will likely result in a "broken pipe" error or something similar.

Other Notes
-----------
Because of how the permissions model has been implemented, this application is not thread safe; it was a trade-off that
was made to allow for a simpler permissions model. Simultaneous processes are fine, but a single multithreaded process
can cause permission inconsistencies. Rack::Lock is therefore being used to ensure thread safety, but this effectively
prevents any potential performance gain by multithreading. This should not be a performance bottleneck though, as the
only advantage of multi-threading over multi-process is that it uses less memory.
