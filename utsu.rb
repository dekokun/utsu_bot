$KCODE = 'u'
require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'cgi'
require 'kconv'
require 'yaml'

def get_utsu_score(user_name,app_id)
    pn_ja = []
    open('../data/pn_ja.dic') do |f|
        while l = f.gets
            pn_ja << l.chomp.toutf8.split(':')
        end
    end

    statuses = twitter_statuses(user_name) #調べたいユーザーのユーザー名を入力
    total_score = 0
    count = 0
    status_all = ""
    statuses.each do |status|
        status_all += status
    end
        doc = open("http://jlp.yahooapis.jp/MAService/V1/parse?appid=#{app_id}&results=ma&response=baseform&sentence=#{CGI.escape(status_all)}"){|f| Hpricot(f)}
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
    print get_utsu_score
end

