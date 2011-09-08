
Requirements
------------
* Ruby 1.9+ with RubyGems
* libxml2-dev and libxslt1-dev package is required to compile the 'nokogiri' gem.
* FreeTDS 0.9.x or later is required to compile the required gem 'tiny_tds'. At the time of writing, 0.9.x was not available via
  apt-get. In this case, download the latest and most stable 0.9.x branch and compile. Configure with: ./configure --enable-msdblib. FreeTDS 0.8.x will not work.
  Note, libsybdb5 is required at runtime by tiny_tds. Install with: sudo apt-get install libsybdb5.