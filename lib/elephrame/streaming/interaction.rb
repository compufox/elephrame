module Elephrame
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

            # this makes it so .content calls strip instead 
            update.status.class.module_eval { alias_method :content, :strip } if @strip_html
            store_mention_data update.status
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
