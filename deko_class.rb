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
  
  

  
  def initialize(bot_name, app_id, password, test_flag)
    @bot_name = bot_name
    @app_id = app_id
    @data_home = File.expand_path(File.dirname(__FILE__)) + '/../data/'
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
    pn_ja = []
    pn_ja_kana = []
    open(@data_home + 'dic/pn_ja.dic') do |f|
      while l = f.gets
        pn_ja << l.chomp.split(':')
      end
    end
    open(@data_home + 'dic/pn_ja_kana.dic') do |f|
      while l = f.gets
        pn_ja_kana << l.chomp.split(':')
      end
    end
    statuses = twitter_statuses(user_name) #調べたいユーザーのユーザー名を入力
    total_score = 0
    count = 0
    status_all = ""
    doc = ""
  
    statuses.each do |status|
      status_all += (status + "。")
    end
  
    Net::HTTP.start('jlp.yahooapis.jp'){|http|
    doc = http.post('/MAService/V1/parse', "appid=#{@app_id}&results=ma&response=baseform&sentence=#{CGI.escape(status_all)}&filter=1|4|9|10").body
    doc =  Hpricot(doc)}
    words = (doc/:baseform).map {|i| i.inner_text}
    score = 0
  
    words.each do |w|
      if w.include?('@')
        next
      elsif w.match(/[ア-ン]/) 
        if i = pn_ja_kana.assoc(w) || i = pn_ja_kana.rassoc(w)
          score += i[3].to_f
          count += 1
        end
      elsif w.match(/[一-龠]/) 
        if i = pn_ja.assoc(w)
          score += i[3].to_f
          count += 1
        end
      elsif i = pn_ja.rassoc(w)
        score += i[3].to_f
        count += 1
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
    doc = open("http://twitter.com/statuses/user_timeline/#{user_name}.xml"){|f| Hpricot(f)}
    (doc/:text).map {|i| i.inner_text}
  end

  def get_utsu_standard(username)
    return 50 + (10 * (get_utsu_score(username) - @average))/(@standard_deviation)
  end



  def get_my_friends(page = nil)
    query = {}
    if page != nil
      query = {"page" => page.to_i}
    end
    @base.followers(query)
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
      if new_request == nil
      #もし最後リプライしていたのが自分だったら何もしない
      elsif screen_name == @bot_name
      elsif already_replied.include?(screen_name)
      else
        happy_word = "@#{screen_name} #{new_request.user.name}さんの最近の幸福偏差値は" + get_utsu_standard(screen_name ).to_s + "です"
  
        @base.update(happy_word) if !@test_flag 
        print "send:@#{screen_name}"
        print " "
        already_replied.push(screen_name)
      end
    end
  end
  
  
  
  
  def write_new_time
    File.open(@new_time_file,"w") do |f|
      f.puts @new_time
    end
  end
end
