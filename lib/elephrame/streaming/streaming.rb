module Elephrame
  module Streaming
    attr :streamer, :last_mention

    ##
    # Creates the stream client
    
    def setup_streaming
      @streamer = Mastodon::Streaming::Client.new(base_url: ENV['INSTANCE'],
                                                  bearer_token: ENV['TOKEN'])
    end

    ##
    # Replies to the last mention it the bot recieved using the mention's
    # visibility and spoiler with +text+
    #
    # @param text [String] text to post as a reply
    
    def reply(text)
      post(text,
           visibility: @last_mention.visibility, reply_id: @last_mention.id,
           spoiler: @last_mention.spoiler_text)
    end
  end
    
  module Reply
    attr :on_reply

    ##
    # Sets on_reply equal to +block+
    
    def on_reply &block
      @on_reply = block
    end

    ##
    # Starts a loop that checks for mentions from the authenticated user account
    # running a supplied block or, if a block is not provided, on_reply
    
    def run_reply
      @streamer.user do |update|
        next unless update.kind_of? Mastodon::Notification and update.type == 'mention'

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

    ##
    # Sets on_fave equal to +block+
    
    def on_fave &block
      @on_fave = block
    end

    ##
    # Sets on_boost to +block+
    
    def on_boost &block
      @on_boost = block
    end

    ##
    # Sets on_follow to +block+
    
    def on_follow &block
      @on_follow = block
    end

    ##
    # Starts a loop that checks for any notifications for the authenticated
    # user, running the appropriate stored proc when needed
    
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
