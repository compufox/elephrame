require 'elephrame'

replier = Elephrame::Bots::Reply.new

replier.run { |bot, mention|
  bot.reply("@#{mention.account.acct} hey!")
}
