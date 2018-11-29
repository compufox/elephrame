require 'elephrame/streaming/streaming'
require 'elephrame/bot'

module Elephrame
  module Bots
    
    # a bot that can respond to all interactions
    class Interact < BaseBot
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
      include Elephrame::Reply

      def initialize
        super()
        
        setup_streaming
      end
    end

  end
end
