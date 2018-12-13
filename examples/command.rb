require 'elephrame'

Candy = [ 'M&Ms', 'Skittles', 'Twix', 'Candycorn' ]
Genders   = [ 'sweet', 'sour', 'bitter', 'creamy', 'umami' ]

# set the prefix and usage string for our bot
cmd_bot = Elephrame::Bots::Command.new '!', 'mention me with !candy to get candy, or !gender to get a gender'

# add in the candy command
cmd_bot.add_command 'candy' do |bot|
  bot.reply("here's some candy!
*gives you a #{Candy.sample}*",
            spoiler: 'candy')
end

# add in the gender command
cmd_bot.add_command 'gender' do |bot|
  bot.reply("here's a spare gender!
*gives you a #{Genders.sample} gender*",
            spoiler: 'gender shitpost')
end

# if the command is not found
cmd_bot.if_not_found do |bot|
  bot.reply("I didn't recognize that! Respond with !help to get usage info")
end

cmd_bot.run
