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
      elsif w.match(/ア-ン/) && (i = pn_ja_kana.assoc(w) || i = pn_ja_kana.rassoc(w))
        score += i[3].to_f
        count += 1
      elsif w.match(/[一-龠]/) && i = pn_ja.assoc(w)
        score += i[3].to_f
        count += 1
      elsif i = pn_ja.rassoc(w)
        score += i[3].to_f
        count += 1
      end
    end
  
    total_score += score
    if count == 0
  
      return 0
  
    else
      return (total_score/count)*100
    end
  end
  
  def twitter_statuses(user_name)
    doc = open("http://twitter.com/statuses/user_timeline/#{user_name}.xml"){|f| Hpricot(f)}
    (doc/:text).map {|i| i.inner_text}
  end


  
  def initialize(test_flag)
    Twitter::HTTPAuth.http_proxy( nil, nil )
    @data_home = File.expand_path(File.dirname(__FILE__)) + '/../data/'
    data_file = File.open(@data_home + "password.yaml")
    user_data = YAML.load(data_file.read)
    data_file.close
 
    @count_file = @data_home + "count.txt"
    @new_time_file = @data_home + "new_time.txt"
 
    @deko_score_file = @data_home + "deko_score.txt"
    @bot_name = user_data['bot_name']
    @my_name = user_data['my_name']
    @app_id = user_data['app_id']
 
    password = user_data['bot_pass']
    @base = Twitter::Base.new( Twitter::HTTPAuth.new( @bot_name , password ) )
    @test_flag = test_flag
  end
  

  def get_my_friends(page = nil)
    query = {}
    puts "page=" + page
    if page != nil
      query = {"page" => page.to_i}
    end
    print "query="
    p query
    @base.friends(query)
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
    @count = get_count
    replies = get_new_replies
    already_replied = []
    replies.each do |new_request|
      screen_name = new_request.user.screen_name.to_s
      if new_request == nil
      #もし最後リプライしていたのが自分だったら何もしない
      elsif screen_name == @bot_name
      elsif already_replied.include?(screen_name)
      else
        happy_word = "@#{screen_name} #{new_request.user.name}さんの最近の幸福度は" + get_utsu_score(screen_name ).to_s + "です"
  
        @base.update(happy_word) if !@test_flag 
        print "send:@#{screen_name}"
        print " "
        already_replied.push(screen_name)
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
      @base.update("最近のポストから見る@dekokun の幸福度は「" + @deko_score.to_s + hagemashi) if !@test_flag
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
  if ARGV[0] == "t"
    test_flag = true
  else
    test_flag == nil
  end

  a = DEKO.new(test_flag)
  p a.get_utsu_score(ARGV[0])

  #a.friends_happy
  #a.dekokun_happy
  #a.write_count
  #a.write_deko_score
  puts ""
end
