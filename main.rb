require 'deko_class.rb'


print Time.now
print " "
if ARGV[0] == "t"
    test_flag = true
else
    test_flag == nil
end

a = DEKO.new(test_flag)
a.friends_happy
a.dekokun_happy
a.write_count
a.write_deko_score
puts ""