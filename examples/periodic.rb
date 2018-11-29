require 'elephrame'

B = Elephrame::Bots::Periodic.new '10s'

B.run do |bot|
  bot.post('testing', visibility: 'direct')
end
