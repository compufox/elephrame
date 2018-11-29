require_relative 'streaming'
require_relative '../bot'

module Elephrame
  module Bots
    
    # a bot that can respond to all interactions
    class Interact < BaseBot
      include Elephrame::Streaming
      include Elephrame::Interacter
      
      def initialize
        super()
        
        setup_streaming
      end
    end

    # a bot that only replies when mentioned
    # run accepts a block, but also supports
    # use of on_reply
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
