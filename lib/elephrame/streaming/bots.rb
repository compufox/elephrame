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

  end
end
