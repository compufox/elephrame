require 'elephrame'
require 'time'

bot = Elephrame::Bots::TraceryBot.new('1h', 'tracery_files2')

# this overrides the default behavior for responding to mentions
bot.on_reply do |bot, post|
    bot.reply_with_mentions("#greeting#, the current hour is #{Time.now}",
                            rules: 'reply')
end

bot.run do |bot|
  # get the current hour
  hour = Time.now.hour
  
  case hour

  when (20..23)
  when (0..5)
    bot.post("The moon is #phase#! It's so spooky :O",
             rules: 'moon')

  when (6..9)
    bot.post("Gotta get up and #activity#!",
             rules: 'morning')

  when (10..16)
    bot.post("Can't wait to #activity# when I get home",
             rules: 'afternoon')

  when (17..19)
    bot.post("Time to start getting ready for #activity#",
             rules: 'night')

  else
    next
  end
end
