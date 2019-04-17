module Elephrame
  module Reply
    attr :on_reply, :mention_data

    ##
    # Sets on_reply equal to +block+
    
    def on_reply &block
      @on_reply = block
    end

    ##
    # Replies to the last mention the bot recieved using the mention's
    #   visibility and spoiler with +text+
    #
    # Automatically includes an @ for the account that mentioned the bot.
    #   Does not include any other @. See +reply_with_mentions+ if you want
    #   to automatically include all mentions
    #
    # @param text [String] text to post as a reply
    # @param options [Hash] a hash of arguments to pass to post, overrides
    #   duplicating settings from last mention 
    
    def reply(text, *options)
      options = Hash[*options]
      
      post("@#{@mention_data[:account].acct} #{text}",
           **@mention_data.merge(options).reject { |k|
             k == :mentions or k == :account
           })
    end

    ##
    # Replies to the last post and tags everyone who was mentioned
    #  (this function respects #NoBot)
    #
    # @param text [String] text to post as a reply
    # @param options [Hash] arguments to pass to post, overrides settings from
    #  last mention

    def reply_with_mentions(text, *options)
      # build up a string of all accounts mentioned in the post
      #  unless that account is our own, or the tagged account
      #  has #NoBot
      mentions = @mention_data[:mentions].collect do |m|
        "@#{m.acct}" unless m.acct == @username or m.no_bot?
      end.join ' '
      
      reply("#{mentions.strip} #{text}", *options)
    end

    ##
    # Starts a loop that checks for mentions from the authenticated user account
    # running a supplied block or, if a block is not provided, on_reply
    
    def run_reply
      @streamer.user do |update|
        next unless update.kind_of? Mastodon::Notification and update.type == 'mention'

        # this makes it so .content calls strip instead 
        update.status.class.module_eval { alias_method :content, :strip } if @strip_html

        store_mention_data update.status
        
        if block_given?
          yield(self, update.status)
        else
          @on_reply.call(self, update.status)
        end
      end
    end

    alias_method :run, :run_reply

    private
    
    ##
    # Stores select data about a post into a hash for later use
    #
    # @param mention [Mastodon::Status] the most recent mention the bot received

    def store_mention_data(mention)
      @mention_data = {
        reply_id: mention.id,
        visibility: mention.visibility,
        spoiler: mention.spoiler_text,
        hide_media: mention.sensitive?,
        mentions: mention.mentions,
        account: mention.account
      }
    end
  end
end
