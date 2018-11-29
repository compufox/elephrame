require 'elephrame'

R = Elephrame::Bots::Interact.new

R.on_reply { |bot, post|
  bot.post("@#{post.account.acct} Thanks for helping me test stuff :3",
           reply_id: post.id, visibility: post.visibility)
}

R.on_fave { |bot, notif|
  puts "#{notif.account.acct} just faved post #{notif.status.content}"
}

R.on_boost { |bot, notif|
  puts "#{notif.account.acct} just boosted post #{notif.status.content}"
}

R.run
