require 'elephrame'

# we define our bot by telling elephrame how often it should post,
#  and where it should load our tracery rules from
bot = Elephrame::Bots::TraceryBot.new('10s', 'tracery_files')

#  this code happens automatically in the framework
#   when there's a rule file for 'reply'
#bot.on_reply do |bot|
#  bot.reply_with_mentions("#default#", rules: 'reply')
#end


# because there's a tracery file named "default" the framework loads
#  it automatically! TraceryBot overloads the default 'post' method
#  and makes sure it automatically expands our tracery text using our
#  loaded grammar
bot.run do |bot|
  bot.post('#greeting#, World! I\'m #sexuality#', visibility: 'unlisted')
end
