require 'elephrame/rest/rest'
require 'elephrame/streaming/streaming'
require 'elephrame/bot'

module Elephrame
  module Bots
    # a bot that posts things on an interval
    # but can also respond to interactions
    class CombinedBot < BaseBot
      include Elephrame::Scheduler
      include Elephrame::AllInteractions
      
      def initialize intv
        super()
        
        setup_scheduler intv
        setup_streaming
      end
      
      def run
        run_scheduled &Proc.new
        run_interact
      end
    end
  end
end
