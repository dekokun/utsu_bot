$KCODE = 'u'
require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'cgi'
require 'kconv'

def get_utsu_score(user_name)
    pn_ja = []
    open('http://www.lr.pi.titech.ac.jp/~takamura/pubs/pn_ja.dic') do |f|
        while l = f.gets
            pn_ja << l.chomp.toutf8.split(':')
        end
    end

    app_id = 'p.OfYxaxg65wzzdXvezZcc7M8Di1ElwJvdogooliIgvGXh0CsSgUtz_TfDqR'
    #Yahoo!のアプリケーションIDを入力
    statuses = twitter_statuses(user_name) #調べたいユーザーのユーザー名を入力
    total_score = 0
    count = 0
    statuses.each do |status|
        doc = open("http://jlp.yahooapis.jp/MAService/V1/parse?appid=#{app_id}&results=ma&response=baseform&sentence=#{CGI.escape(status)}"){|f| Hpricot(f)}
        words = (doc/:baseform).map {|i| i.inner_text}
        score = 0
        words.each do |w|
            if w.include?('@')
                next
            elsif i = pn_ja.assoc(w)
                score += i[3].to_f
                count += 1
            elsif i = pn_ja.rassoc(w)
                score += i[3].to_f
                count += 1
            end
        end
        total_score += score
    end
    if count == 0
        return 0
    else
        (total_score/count)*100
    end
end

def twitter_statuses(user_name)
    doc = open("http://twitter.com/statuses/user_timeline/#{user_name}.xml"){|f| Hpricot(f)}
    (doc/:text).map {|i| i.inner_text}
end

if __FILE__ == $0
    print utsu_score
end
