
Requirements
------------
* Ruby 1.9+ with RubyGems
* libxml2-dev and libxslt1-dev package is required to compile the 'nokogiri' gem.
* FreeTDS 0.9.x or later is required to compile the required gem 'tiny_tds'. At the time of writing, 0.9.x was not
  available via apt-get. In this case, download the latest and most stable 0.9.x branch and compile. Configure with:
  ./configure --enable-msdblib. FreeTDS 0.8.x will not work. Note, libsybdb5 is required at runtime by tiny_tds.
  Install with: sudo apt-get install libsybdb5.
* imagemagick is required for thumbnail generation (apt-get install imagemagick or brew install imagemagick)
  
Installation
------------
1) Get a copy of the files by either copying and pasting, or pushing/pulling from git.
2) `cd` into directory.
3) ```gem install bundler
4) ```bundle install

Migrations
----------
SQL migrations are located in the root of the application in the /db directory. To run, use the _sequel_ command line
tool. As an example:

```sequel -m /db "tinytds://server.trc.local/database?username=username&password=password"

Note, if the username or password contain special characters that invalidate the URI, such as a backslash, you must URI
encode them, so for example, the backslash would become %5C.

Mail
----
Sendmail (or something sendmail-compatible) is required for email capability, such as notifications. If it's not installed, attempts to email will likely
result in a "broken pipe" error or something similar.

Other Notes
-----------
Because of how the permissions model has been implemented, this application is not thread safe. Simultaneous processes
are fine, but a single multithreaded process can cause permission inconsistancies. Rack::Lock is therefore being used
to ensure thread safety, but this effectively prevents any potential performance gain by multithreading.