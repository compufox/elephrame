require 'elephrame'

# create a bot that watches the public timeline
#  (this gives us the largest sample size)
watcher = Elephrame::Bots::Watcher.new 'public'

watcher.run do |bot, post|

  # if the account's profile doesn't contain no bot
  #  we print the account's handle and the post's content
  if not bot.no_bot? post.account.id
    puts "#{post.account.acct}: #{post.content}"
  end
end
