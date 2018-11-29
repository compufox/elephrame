module Elephrame
  module Streaming
    attr :streamer

    def setup_streaming
      @streamer = Mastodon::Streaming::Client.new(base_url: ENV['INSTANCE'],
                                                  bearer_token: ENV['TOKEN'])
    end
  end
    
  module Reply
    attr :on_reply

    def on_reply &block
      @on_reply = block
    end

    def run_reply
      @streamer.user do |update|
        next unless update.kind_of? Mastodon::Notification && update.type == 'mention'

        if block_given?
          yield(self, update.status)
        else
          @on_reply.call(self, update.status)
        end
      end
    end

    alias_method :run, :run_reply
  end
  
  module AllInteractions
    include Elephrame::Reply
    attr :on_fave, :on_boost, :on_follow
    
    def on_fave &block
      @on_fave = block
    end
    
    def on_boost &block
      @on_boost = block
    end
    
    def on_follow &block
      @on_follow = block
    end
    
    def run_interact
      @streamer.user do |update|
        if update.kind_of? Mastodon::Notification
          
          case update.type
              
          when 'mention'
            @on_reply.call(self, update.status) unless @on_reply.nil?
            
          when 'reblog'
            @on_boost.call(self, update) unless @on_boost.nil?
            
          when 'favourite'
            @on_fave.call(self, update) unless @on_fave.nil?
            
          when 'follow'
            @on_follow.call(self, update) unless @on_follow.nil?
            
          end
        end
      end
    end

    
    alias_method :run, :run_interact
  end
end
