#! /usr/bin/ruby

require 'optparse'
require 'yaml'
require File.expand_path(File.dirname(__FILE__)) + '/deko_class.rb'

OPTS = {}
OptionParser.new do |opt|
  opt.on('-t',"no post to twitter") {|v| OPTS[:t] = v }
  opt.on('-u USERNAME',"the name you want measure happy level") {|v| OPTS[:u] = v }
  opt.parse!(ARGV)
end


data_home = File.expand_path(File.dirname(__FILE__)) + '/../data/'

user_data = ''

File.open(data_home + "password.yaml", 'r') do | userdata_file |
    user_data = YAML.load(userdata_file.read)
end

bot_name = user_data['bot_name']
app_id = user_data['app_id']
password = user_data['bot_pass']


print Time.now
print " "


if OPTS[:t]
  print "テスト状態です。";
  test_flag = true
else
  test_flag = nil
end

utsu_bot = DEKO.new(bot_name, app_id, password, test_flag)

if OPTS[:u]
  puts "指定されたユーザの幸福度を測ります"
  test_flag = true
  puts utsu_bot.get_utsu_standard(OPTS[:u])
else
  utsu_bot.friends_happy
  puts ""
end
