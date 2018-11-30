require 'elephrame'

interacter = Elephrame::Bots::Interact.new

interacter.on_reply { |bot, post|

  #bot.post("@#{post.account.acct} Thanks for helping me test stuff :3",
  #           reply_id: post.id, visibility: post.visibility)
  
  ## this can be simplified to one line
  bot.reply("@#{post.account.acct} Thanks for helping me test stuff :3")
}

interacter.on_fave { |bot, notif|
  puts "#{notif.account.acct} just faved post #{notif.status.content}"
}

interacter.on_boost { |bot, notif|
  puts "#{notif.account.acct} just boosted post #{notif.status.content}"
}

interacter.run
