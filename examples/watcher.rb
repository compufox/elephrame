require 'elephrame'

# here are various examples of how to create a new watcher bot
#tag_watcher   = Elephrame::Bots::Watcher.new 'tag', 'CoolHash'
#local_watcher = Elephrame::Bots::Watcher.new 'local'
#ltag_watcher  = Elephrame::Bots::Watcher.new 'local hashtag', 'LocalTag'
#list_watcher  = Elephrame::Bots::Watcher.new 'list', 'test list'
#home_watcher  = Elephrame::Bots::Watcher.new 'home'

fedi_watcher = Elephrame::Bots::Watcher.new 'public'

fedi_watcher.run do |bot, post|
  puts "#{post.account.acct}: #{post.content}"
end
