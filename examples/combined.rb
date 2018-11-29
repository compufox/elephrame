require 'elephrame'

mix = Elephrame::Bots::CombinedBot.new '30s'

mix.on_reply { |bot, post|
  bot.post("@#{post.account.acct} Thanks for helping me test stuff :3",
           reply_id: post.id, visibility: post.visibility)
}

mix.on_fave { |bot, notif|
  puts "#{notif.account.acct} just faved post #{notif.status.content}"
}

mix.on_boost { |bot, notif|
  puts "#{notif.account.acct} just boosted post #{notif.status.content}"
}

mix.run do |bot|
  bot.post('testing', visibility: 'direct')
end
