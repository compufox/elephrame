require 'elephrame/version'
require 'elephrame/bot_definitions'
require 'mastodon'


module Elephrame  
  module Bots
    
    # a superclass for other bots
    # holds common functions and the rest api client
    class BaseBot
      include Elephrame::Bot

      def initialize
        @client = Mastodon::REST::Client.new(base_url: ENV['INSTANCE'],
                                             bearer_token: ENV['TOKEN'])
      end
    end

    # a bot that runs commands based off of
    # an interval or a cron string
    class Periodic < BaseBot
      include Elephrame::Scheduler
      
      def initialize intv
        super()
        
        setup_scheduler intv
      end
    end

    # a bot that can respond to interactions
    class Interact < BaseBot
      include Elephrame::Interacter
      
      def initialize
        super()
        
        setup_streamer
      end
    end

    # a bot that posts things on an interval
    # but can also respond to interactions
    class CombinedBot < BaseBot
      include Elephrame::Scheduler
      include Elephrame::Interacter
      
      def initialize intv
        super()
        
        setup_scheduler intv
        setup_streamer
      end
      
      def run
        run_scheduled &Proc.new
        run_interact
      end
    end
  end
end
