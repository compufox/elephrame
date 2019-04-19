require 'elephrame'

# tell the bot how often to post, and where to find it's source material,
#  then we go and set options for it
marxkov = Elephrame::Bots::MarkovBot.new '3h', 'markov_files',
                                         visibility: 'unlisted', cw: 'markov post'

# then we tell the bot to post
marxkov.run
                                         










