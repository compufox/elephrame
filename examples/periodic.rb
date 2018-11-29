require 'elephrame'

periodic = Elephrame::Bots::Periodic.new '10s'

periodic.run do |bot|
  bot.post('testing', visibility: 'direct')
end
