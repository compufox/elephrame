module Elephrame
  module Bot
    attr_reader :client
    
    def post(text, visibility: 'unlisted', spoiler: '', reply_id: '', media: [])
      
      if not media.empty?
        media.collect! {|m|
          @client.upload_media(m).id
        }
      end
      
      options = {
        visibility: visibility,
        spoiler_text: spoiler,
        in_reply_to_id: reply_id,
        media_ids: media,
      }
      
      @client.create_status text, options
    end
  end
  
  module Scheduler
    attr :scheduler, :interval
    
    def setup_scheduler intv
      require 'rufus-scheduler'
      
      
      @interval = intv
      @scheduler = Rufus::Scheduler.new
    end
    
    def run_scheduled
      @scheduler.repeat @interval do
        yield(self)
      end
      @scheduler.join unless not @streamer.nil?
    end

    alias_method :run, :run_scheduled
  end
  
  module Interacter
    attr :streamer, :on_fave, :on_boost,
         :on_reply, :on_follow
    
    def setup_streamer
      @streamer = Mastodon::Streaming::Client.new(base_url: ENV['INSTANCE'],
                                                  bearer_token: ENV['TOKEN'])
    end
    
    def on_fave &block
      @on_fave = block
    end
    
    def on_boost &block
      @on_boost = block
    end
    
    def on_reply &block
      @on_reply = block
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
