#!/usr/bin/env bash

# load rvm ruby
bundle install
ruby crawl.rb >/dev/null 2>/dev/null
