#!/usr/bin/env bash

# load rvm ruby
source /Users/sei/.rvm/environments/ruby-1.9.2-p290

bundle install
ruby /Users/sei/github/homosure/crawl.rb >/dev/null 2>/dev/null
