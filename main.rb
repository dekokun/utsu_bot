require File.expand_path(File.dirname(__FILE__)) + '/deko_class.rb'

print Time.now
print " "
if ARGV[0] == "t"
  print "テスト状態です。";
  test_flag = true
else
  test_flag == nil
end

a = DEKO.new(test_flag)
a.friends_happy
puts ""
