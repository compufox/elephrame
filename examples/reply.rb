require 'elephrame'

replier = Elephrame::Bots::Reply.new

replier.run { |bot|
  bot.reply("hey!")
}
