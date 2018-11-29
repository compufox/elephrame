require 'elephrame/rest/rest'
require 'elephrame/bot'

module Elephrame
  module Bots
    # a bot that runs commands based off of
    # an interval or a cron string
    class Periodic < BaseBot
      include Elephrame::Scheduler
      
      def initialize intv
        super()
        
        setup_scheduler intv
      end
    end
  end
end
