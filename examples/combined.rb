require 'elephrame'

C = Elephrame::Bots::CombinedBot.new '30s'

C.on_reply { |bot, post|
  bot.post("@#{post.account.acct} Thanks for helping me test stuff :3",
           reply_id: post.id, visibility: post.visibility)
}

C.on_fave { |bot, notif|
  puts "#{notif.account.acct} just faved post #{notif.status.content}"
}

C.on_boost { |bot, notif|
  puts "#{notif.account.acct} just boosted post #{notif.status.content}"
}

C.run do |bot|
  bot.post('testing', visibility: 'direct')
end
