# -*- coding: utf-8 -*-
require 'bundler/setup'

require 'sequel'
require 'sqlite3'
require 'twitter'
require 'mechanize'

config = YAML.load_file("config.yml")
Twitter.configure do |c|
  c.consumer_key = config["CONSUMER_KEY"]
  c.consumer_secret = config["CONSUMER_SECRET"]
  c.oauth_token = config["ACCESS_TOKEN"]
  c.oauth_token_secret = config["ACCESS_TOKEN_SECRET"]
end

DB = Sequel.sqlite('homosure.db')

if !DB.table_exists? :urls
  DB.create_table :urls do
    primary_key :id
    foreign_key :url_id, :urls
    String :title
    String :url
    DateTime :created_at
    index [:url_id, :created_at]
  end
end

tweets = Twitter.search "ホモスレ", :lang => "ja", :rpp => 100, :include_entities => 1
urls = tweets.select{|t|
  not t.attrs["entities"].empty?
}.select{|t|
  t.attrs["entities"]["urls"]
}.map{|t|
  t.attrs["entities"]["urls"].map{|u| u["expanded_url"]}
}.inject([]) {|result, urls|
  result + urls
}.select{|u|
  DB[:urls].where(:url => u).count.zero?
}.uniq

agent = Mechanize.new

urls_for_tweet = []

urls.each do |u|
  agent.get u
  expanded_url = agent.page.uri.to_s
  
  url_data = {
    :title => agent.page.title,
    :url => expanded_url,
    :created_at => Time.now()
  }
  
  if DB[:urls].where(:url => u).count.zero?
    url_id = DB[:urls].insert url_data
    urls_for_tweet << url_data
  else
    url_id = DB[:urls].where(:url => u).first[:id]
  end
  
  if u != expanded_url
    url_data = {
      :title => agent.page.title,
      :url_id => url_id,
      :url => u,
      :created_at => Time.now()
    }
    DB[:urls].insert url_data
  end
end

urls_for_tweet.each do |u|
  Twitter.update u[:title][0..100] + " " + u[:url]
  sleep 1
end
