require 'elephrame'

# So, we want to create an ebook bot
#   all of the hardwork is done in the backend by the framework!
#
# we just need to make sure the account we're posting from is set up right
#  make sure that the ebooks account is following all of the accounts you
#  want to generate posts from (e.g., if you just want it to be a personal
#                               ebooks bot then just have it follow you,
#                               if you want it to generate posts from everyone
#                               in a group then make sure it follows them all)
# 
# once that's taken care of we need to tell the framework some options for our bot
#  how often to post, how often to get new statuses from the accounts it's following
#  what the CW should be for all of its posts (this is polite ;3  )
#  what the lowest level visiblility setting we should grab to generate from
#
# thats just what ive supplied in this example, but there are more options!
#  to see them all please check the documentation (see main README for link)
bot = Elephrame::Bots::EbooksBot.new '1m', update_interval: '2d',
                                     cw: 'ebooks post', scrape_privacy: 'unlisted'

# run the bot!
bot.run
