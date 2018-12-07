require_relative 'streaming'
require_relative '../bot'

module Elephrame
  module Bots
    
    ##
    # a bot that can respond to all interactions
    #
    # Call on_fave, on_follow, on_reply, or on_boost with a block
    # before calling run. Otherwise bot will do nothing.
    
    class Interact < BaseBot
      include Elephrame::Streaming
      include Elephrame::AllInteractions
      
      def initialize
        super()
        
        setup_streaming
      end
    end


    ##
    # a bot that only replies when mentioned
    #
    # run accepts a block, but also supports
    # use of on_reply (See Elephrame::AllInteractions for more details)
    
    class Reply < BaseBot
      include Elephrame::Streaming
      include Elephrame::Reply

      def initialize
        super()
        
        setup_streaming
      end
    end


    ##
    # A bot that responds to commands, 
    #
    # after creation make sure to call add_command or else your bot won't
    # know what to respond to! (See [Elephrame::Command] for more details
    
    class Command < BaseBot
      include Elephrame::Streaming
      include Elephrame::Command

      ##
      # Create a new Command bot, sets +commands+ and +cmd_hash+ to empty
      # defaults
      #
      # @param prefix [String] sets the command prefix, defaults to '!'
      # @param usage [String] the response to the help command
      #
      # @return [Elephrame::Bots::Command]
      
      def initialize prefix = '!', usage = nil
        super()

        @commands = []
        @cmd_hash = {}
        
        setup_streaming
        set_prefix prefix
        set_help usage unless usage.nil?
      end
    end

  end
end
