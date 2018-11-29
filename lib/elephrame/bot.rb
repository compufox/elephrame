module Elephrame  
  module Bots
    
    # a superclass for other bots
    # holds common functions and the rest api client
    class BaseBot
      attr_reader :client

      def initialize
        @client = Mastodon::REST::Client.new(base_url: ENV['INSTANCE'],
                                             bearer_token: ENV['TOKEN'])
      end
      
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

  end
end

