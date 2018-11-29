require_relative 'rest'
require_relative '../bot'

module Elephrame
  module Bots

    ##
    # a bot that runs commands based off of
    # an interval or a cron string

    class Periodic < BaseBot
      include Elephrame::Scheduler

      ##
      # creates a new Periodic bot
      #
      # @param intv [String] string specifying interval to post.
      #   ex: '3h' (every 3 hours) '20m' (every 20 minutes)
      #       '00 12 * * *' (every day at 12:00)
      #       '00 00 25 12 *' (midnight on christmas)
      #
      # @return [Elephrame::Bots::Periodic]
      
      def initialize intv
        super()
        
        setup_scheduler intv
      end
    end
  end
end
