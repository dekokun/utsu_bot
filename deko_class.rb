#! /usr/bin/ruby

class DEKO 
   
   require 'net/https' 
   require 'open-uri'
   require 'cgi'
   require 'rubygems'
   require 'twitter'
   require 'yaml'
   require File.expand_path(File.dirname(__FILE__)) + '/utsu.rb'
   
   def initialize()
       @data_home = File.expand_path(File.dirname(__FILE__)) + '/../data/'
       Twitter::HTTPAuth.http_proxy( nil, nil )
       data_file = File.open(@data_home + "password.yaml")
       user_data = YAML.load(data_file.read)
       data_file.close

       @count_file = @data_home + "count.txt"
       @new_time_file = @data_home + "new_time.txt"

       @deko_score_file = @data_home + "deko_score.txt"
       @bot_name = user_data['bot_name']
       @my_name = user_data['my_name']

       password = user_data['bot_pass']
       @base = Twitter::Base.new( Twitter::HTTPAuth.new( @bot_name , password ) )

   end
   
   def get_my_friends
       @base.followers
   end
   
   
   def get_count
       File.open(@count_file,"a+") do |f|
           count = f.gets
           if count == nil
               return "0"
           else
               return count.chomp
           end
       end
   end
   
   def get_new_time
       File.open(@new_time_file,"a+") do |f|
           new_time = f.gets
           if new_time == nil
               return "0"
           else
               return new_time.chomp
           end
       end
   end
   
   def get_deko_score
       File.open(@deko_score_file,"a+") do |f|
           deko_score = f.gets
           if deko_score == nil
               return "0"
           else
               return deko_score.chomp
           end
       end
   end
   
   
   #前回の起動で取得していないリプライを配列で返す
   def get_new_replies
       replies = @base.replies
       p new = get_new_time
       new_replies = []
       @new_time = replies[0].created_at
       p "test"
       p new
       replies.each do |reply|
           p reply.created_at
           if reply.created_at == new
               return new_replies
           else 
               new_replies.push(reply)
           end
       end
       write_new_time
       return new_replies
   end
   
   
   def friends_happy
       @count = get_count
       p 1
       replies = get_new_replies
       p 2
       replies.each do |new_request|
           if new_request==nil
           #もし最後リプライしていたのが自分だったら何もしない
           elsif new_request.user.screen_name.to_s == @bot_name
           else
               happy_word = "@#{new_request.user.screen_name} #{new_request.user.name}さんの最近の幸福度は" + get_utsu_score(new_request.user.screen_name).to_s + "です"
   
               @base.update(happy_word)
               print "@#{new_request.user.screen_name}"
               print " "
               p 3
           end
       end
   end
   
   
   def dekokun_happy
       #以下、自分の幸福度のお知らせ
       @count = get_count
       @deko_score = get_deko_score
       if (@count.to_i % 60 == 0) && (@deko_score.to_i != (@deko_score = get_utsu_score(@my_name)))
           if @deko_score >= 0
             hagemashi = "」です。最近の@dekokun は珍しく多少の幸せにひたっているみたいです。祝福のリプライでもしてあげましょう"
           else
               hagemashi = "」です。@dekokun をなぐさめてあげましょう"
           end
           @base.update("最近のポストから見る@dekokun の幸福度は「" + @deko_score.to_s + hagemashi)
           print "deko_score:"
           print @deko_score
           print " "
       end
   end
   
   def write_count
       File.open(@count_file,"w") do |f|
           next_count = @count.to_i + 1
           f.puts next_count.to_s
       end
   end
   
   def write_new_time
       File.open(@new_time_file,"w") do |f|
           f.puts @new_time
       end
   end
   
   def write_deko_score
       File.open(@deko_score_file,"w") do |f|
           f.puts @deko_score
       end
   end
   
end

if $0 == __FILE__
    print Time.now
    print " "
    a = DEKO.new()
    a.friends_happy
    a.dekokun_happy
    a.write_count
    a.write_new_time
    a.write_deko_score
    print "\n"
end
