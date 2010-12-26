#! /usr/bin/ruby

require 'optparse'
require 'yaml'
require 'rubygems'
require 'twitter'
require 'pg'
require File.expand_path(File.dirname(__FILE__)) + '/deko_class.rb'

OPTS = {}
OptionParser.new do |opt|
  opt.on('-t',"no post to twitter") {|v| OPTS[:t] = v }
  opt.on('-u USERNAME',"the name you want measure happy level") {|v| OPTS[:u] = v }
  opt.parse!(ARGV)
end



data_home = File.expand_path(File.dirname(__FILE__)) + '/../data/'

config_data = ''

File.open(data_home + "config.yaml", 'r') do | userdata_file |
    config_data = YAML.load(userdata_file.read)
end

bot_name = config_data['bot_name']
app_id = config_data['app_id']
db_pass = config_data['db_pass']
db_user = config_data['db_user']
db_host = config_data['db_host']
db_port = config_data['db_port']
db_name = config_data['db_name']

app_token = config_data['app_token']
user_atoken = config_data['user_atoken']


print Time.now
print " "


if OPTS[:t]
  print "テスト状態です。";
  test_flag = true
else
  test_flag = nil
end


oauth = Twitter::OAuth.new(*app_token)
oauth.authorize_from_access(*user_atoken)
base = Twitter::Base.new(oauth) 


PGconn.connect(db_host, db_port, "", "", db_name, db_user, db_pass) do |conn|

  utsu_bot = UTSU_BOT.new(bot_name, app_id, test_flag, conn, base)
  
  if OPTS[:u]
    puts "指定されたユーザの幸福度を測ります"
    test_flag = true
    puts utsu_bot.get_utsu_standard(utsu_bot.get_utsu_score(OPTS[:u]))
  else
    utsu_bot.friends_happy
    puts ""
  end
end
