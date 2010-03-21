#! /usr/bin/ruby

class DEKO

  $KCODE = 'u'
  require 'net/https'
  require 'open-uri'
  require 'cgi'
  require 'rubygems'
  require 'twitter'
  require 'yaml'
  require 'hpricot'
  require 'kconv'
  require 'jcode'
  Net::HTTP.version_1_2




  def initialize(bot_name, app_id, password, test_flag, conn)
    @bot_name = bot_name
    @app_id = app_id
    @data_home = File.expand_path(File.dirname(__FILE__)) + '/../data/'
    @conn = conn
    numeric_data = '';

    Twitter::HTTPAuth.http_proxy( nil, nil )

    File.open(@data_home + "numerical_value.yaml") do |numericdata_file |
      numeric_data = YAML.load(numericdata_file.read)
    end

    @new_time_file = @data_home + "new_time.txt"


    @average = numeric_data['average'].to_f
    @standard_deviation = numeric_data['standard_deviation'].to_f


    @base = Twitter::Base.new( Twitter::HTTPAuth.new( @bot_name , password ) )
    @test_flag = test_flag

  end


  def get_utsu_score(user_name)
    statuses_array = twitter_statuses(user_name)
    statuses = ""
    statuses_array.each do |timeline|
      statuses += (timeline.text + "。")
    end
    total_score = 0
    count = 0
    score = 0
    doc = ""


    Net::HTTP.start('jlp.yahooapis.jp') do |http|
      doc = http.post('/MAService/V1/parse', "appid=#{@app_id}&results=ma&response=baseform&sentence=#{CGI.escape(statuses)}&filter=1|4|9|10").body
      doc =  Hpricot(doc)
    end
    words = (doc/:baseform).map {|i| i.inner_text}

    words.each do |w|
      #w = @conn.quote_ident(w)
      w.gsub!(/['\/"]/) {|ch| ch + ch }
      if w.include?('@')
        next
      elsif w.match(/[ア-ン]/)
        word_sql=<<EOF
        select score 
         from dic_katakana 
         where word = '#{w}';
EOF
        kana_sql=<<EOF
        select score 
         from dic_katakana 
         where kana = '#{w}';
EOF

        if (res = @conn.query(word_sql)).ntuples != 0
          score += res[0]['score'].to_f
          count += 1
        elsif (res = @conn.query(kana_sql)).ntuples != 0
          score += res[0]['score'].to_f
          count += 1
        end
      elsif w.match(/[一-龠]/)
        sql=<<EOF
        select score 
         from dic_kanji_hiragana 
         where word = '#{w}';
EOF
        if (res = @conn.query(sql)).ntuples != 0
          score += res[0]['score'].to_f
          count += 1
        end
      else
        sql=<<EOF
        select score 
         from dic_kanji_hiragana 
         where kana = '#{w}';
EOF
        if (res = @conn.query(sql)).ntuples != 0
          score += res[0]['score'].to_f
          count += 1
        end
      end
    end

    total_score += score
    if count == 0

      return 0

    else
      return (total_score/count)
    end
  end

  def twitter_statuses(user_name)
    query = {}
    query[:id] = user_name
    statuses = @base.user_timeline(query)
    return statuses
  end

  def get_utsu_standard(utsu_score)
      return 50 + (10 * (utsu_score - @average))/(@standard_deviation)
  end

  def get_follower(user)
    query = {}
    query[:id] = user
    next_cursor = -1
    all_followers = []
    while next_cursor != 0
      query[:cursor] = next_cursor
      followers = @base.followers(query)
      followers.users.each do |follower|
        all_followers.push(follower.screen_name)
      end
      next_cursor = followers.next_cursor
    end
    all_followers
  end

  def get_friends(user)
    query = {}
    query[:id] = user
    next_cursor = -1
    all_friends = []
    while next_cursor != 0
      query[:cursor] = next_cursor
      friends = @base.friends(query)
      friends.users.each do |friend|
        all_friends.push(friend.screen_name)
      end
      next_cursor = friends.next_cursor
    end
    all_friends
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



  #前回の起動で取得していないリプライを配列で返す
  def get_new_replies
    replies = @base.mentions
    old_new_time = get_new_time
    new_replies = []
    @new_time = replies[0].created_at
    write_new_time
    replies.each do |reply|
      if reply.created_at == old_new_time
        return new_replies
      else
        new_replies.push(reply)
      end
    end
    return new_replies
  end


  def friends_happy
    replies = get_new_replies
    already_replied = []
    replies.each do |new_request|
      screen_name = new_request.user.screen_name.to_s
      status_id = new_request.id
      query = {}
      query[:in_reply_to_status_id] = status_id
      if new_request == nil
      #もし最後リプライしていたのが自分だったら何もしない
      elsif screen_name == @bot_name
      elsif already_replied.include?(screen_name)
      else
        up_score = (get_utsu_standard(get_utsu_score(screen_name))*10).round.to_f / 10
        happy_word = "@#{screen_name} #{new_request.user.name}さんの最近の幸福偏差値は" + up_score.to_s + "です"

        @base.update(happy_word,query) if !@test_flag
        print "send:@#{screen_name}"
        print " "
        print happy_word if @test_flag
        already_replied.push(screen_name)
      end
    end
  end

  def is_protected?(user)
    user_information = @base.user(user)
    return user_information.protected
  end


  def write_new_time
    File.open(@new_time_file,"w") do |f|
      f.puts @new_time
    end
  end
end
