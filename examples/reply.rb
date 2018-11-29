require 'elephrame'

replier = Elephrame::Bots::Reply.new

replier.run { |bot, mention|
  bot.post("@#{mention.account.acct} hey!", reply_id: mention.id,
           visibility: mention.visibility)
}
