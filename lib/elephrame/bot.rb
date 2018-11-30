module Elephrame  
  module Bots

    ##
    # a superclass for other bots
    # holds common functions and variables
    
    class BaseBot
      attr_reader :client, :username
      attr_accessor :strip_html

      ##
      # Sets up our REST client, gets and saves our username, sets default
      # value for strip_html (true)
      #
      # @return [Elephrame::Bots::BaseBot]
      
      def initialize
        @client = Mastodon::REST::Client.new(base_url: ENV['INSTANCE'],
                                             bearer_token: ENV['TOKEN'])
        @username = @client.verify_credentials().acct
        @strip_html = true
      end

      ##
      # Creates a post, uploading media if need be
      #
      # @param text [String] text to post
      # @param visibility [String] visibility level
      # @param spoiler [String] text to use as content warning
      # @param reply_id [String] id of post to reply to
      # @param hide_media [Bool] should we hide media?
      # @param media [Array<String>] array of file paths
      
      def post(text, visibility: 'unlisted', spoiler: '',
               reply_id: '', hide_media: false, media: [])

        uploaded_ids = []
        unless media.size.zero?
          uploaded_ids = media.collect {|m|
            @client.upload_media(m).id
          }
        end
        
        options = {
          visibility: visibility,
          spoiler_text: spoiler,
          in_reply_to_id: reply_id,
          media_ids: media,
          sensitive: hide_media,
        }
        
        @client.create_status text, options
      end

      
      ##
      # Finds most recent post by bot in the ancestors of a provided post
      #
      # @param id [String] post to base search off of
      # @param depth [Integer] max number of posts to search
      # @param stop_at [Integer] defines which ancestor to stop at
      #
      # @return [Mastodon::Status]
      
      def find_ancestor(id, depth = 10, stop_at = 1)
        depth.each {
          post = @client.status(id) unless id.nil?
          id = post.id

          stop_at -= 1 if post.account.acct == @username

          return post if stop_at.zero?
        }

        return nil
      end

      ##
      # Checks to see if a user has some form of "#NoBot" in their bio
      # (so we can make make friendly bots easier!)
      #
      # @param account_id [String] id of account to check bio
      #
      # @return [Bool]

      def no_bot? account_id
        @client.account(account_id).note =~ /#?NoBot/i
      end
      
    end
  end
end

