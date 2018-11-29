require_relative '../rest/rest'
require_relative '../streaming/streaming'
require_relative '../bot'

module Elephrame
  module Bots
    
    ##
    # a bot that posts things on an interval but can also respond
    # to interactions
    #
    # requires on_* variables to be set before running, otherwise the bot
    # won't react to interactions
    
    class PeriodInteract < BaseBot
      include Elephrame::Scheduler
      include Elephrame::AllInteractions

      ##
      # creates a new PeriodInteract bot
      #
      # @param intv [String] string specifying interval to post
      #
      # @return [Elephrame::Bots::PeriodInteract]
      
      def initialize intv
        super()
        
        setup_scheduler intv
        setup_streaming
      end

      ##
      # Runs the bot. requires a block for periodic post logic, but relies on
      # on_* functions for interaction logic. See Elephrame::AllInteractions
      # for more details.
      
      def run
        run_scheduled &Proc.new
        run_interact
      end
    end
  end
end
