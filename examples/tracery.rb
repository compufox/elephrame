require 'elephrame'

bot = Elephrame::Bots::TraceryBot.new('10s', 'tracery_files')

# because there's a tracery file named "default" the framework loads
#  it automatically! TraceryBot overloads the default 'post' method
#  and makes sure it automatically expands our tracery text using our
#  loaded grammer
bot.run do |bot|
  bot.post('#greeting#, World! I\'m #sexuality#', visibility: 'unlisted')
end
