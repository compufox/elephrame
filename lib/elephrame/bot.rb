module Elephrame  
  module Bots
    
    # a superclass for other bots
    # holds common functions and variables
    class BaseBot
      attr_reader :client

      def initialize
        @client = Mastodon::REST::Client.new(base_url: ENV['INSTANCE'],
                                             bearer_token: ENV['TOKEN'])
      end

      ##
      # Creates a post, uploading media if need be
      #
      # @param text [String] text to post
      # @param visibility [String] visibility level
      # @param spoiler [String] text to use as content warning
      # @param reply_id [String] id of post to reply to
      # @param media [Array<String>] array of file paths
      
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

