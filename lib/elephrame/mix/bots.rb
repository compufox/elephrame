require_relative '../rest/rest'
require_relative '../streaming/streaming'
require_relative './tracery'
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
      include Elephrame::Streaming
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

    ##
    # a bot that posts things on an interval but can also respond
    # to interactions, providing a grammer object and a few helper 
    # methods to easily create bots with tracery.
    #
    # set on_reply before running, otherwise the bot
    # won't react to mentions
    
    class TraceryBot < BaseBot
      backup_method :post, :actually_post
      
      include Elephrame::Streaming
      include Elephrame::Scheduler
      include Elephrame::Reply
      include Elephrame::Trace

      ##
      # create a new TraceryBot
      # @param interval [String] a string representing the interval to post
      # @param tracery_dir [String] a string with the path to the directory
      #    containing all of the tracery grammer rules.
      # @return [Elephrame::Bots::TraceryBot]
      
      def initialize interval, tracery_dir
        super()

        # set up our bot stuff
        setup_scheduler interval
        setup_streaming
        setup_tracery tracery_dir
      end

      ##
      # Runs the bot. requires a block for periodic post logic, but relies on
      # on_* functions for interaction logic. See Elephrame::AllInteractions
      # for more details.
      
      def run
        run_scheduled &Proc.new
        
        unless @on_reply.nil?
          run_reply
        else
          @scheduler.join
        end
      end
    end
  end
end
