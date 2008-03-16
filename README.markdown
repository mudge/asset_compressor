AssetCompressor
===============

Based on both AssetPackager and Rails 2.0's built-in asset caching capabilities, this plugin
will concatenate and compress any specified Javascript and Cascading Style Sheets using
Yahoo!'s excellent YUI Compressor.

To use, instead of using Rails' own `javascript_include_tag` and `stylesheet_link_tag`,
use `javascript_include_compressed` and `stylesheet_link_compressed` like so:

    <%= javascript_include_compressed 'compressed_javascript.js', 'javascript.js', 'javascript2.js' %>

Copyright (c) 2007 Paul Mucur, released under the MIT license

YUI Compressor is Copyright (c) 2006 Yahoo! Inc. All rights reserved.
