module Elephrame
  module Streaming
    attr :streamer

    ##
    # Creates the stream client
    
    def setup_streaming
      @streamer = Mastodon::Streaming::Client.new(base_url: ENV['INSTANCE'],
                                                  bearer_token: ENV['TOKEN'])
    end

  end

  
  module Reply
    attr :on_reply, :mention_data

    ##
    # Sets on_reply equal to +block+
    
    def on_reply &block
      @on_reply = block
    end

    ##
    # Replies to the last mention the bot recieved using the mention's
    # visibility and spoiler with +text+
    #
    # *DOES NOT AUTOMATICALLY INCLUDE @'S*
    #
    # @param text [String] text to post as a reply
    # @param options [Hash] a hash of arguments to pass to post, overrides
    #   duplicating settings from last mention 
    
    def reply(text, *options)
      options = Hash[*options]
      
      # maybe also @ everyone from the mention? idk that seems like a bad idea tbh
      post(text, **@mention_data.merge(options).reject { |k| k == :mentions })
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
        mentions: mention.mentions,
        hide_media: mention.sensitive?
      }
    end
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

  
  module Command
    include Elephrame::Reply
    
    attr_reader :commands, :prefix
    attr :cmd_hash, :cmd_regex, :not_found

    ##
    # sets the prefix for commands
    #
    # @param pf [String] the prefix

    def set_prefix pf
      @prefix = pf
    end

    ##
    # Shortcut method to provide usage docs in response to help command
    #
    # @param usage [String] 
    
    def set_help usage
      add_command 'help' do |bot, content, status|
        bot.reply("@#{status.account.acct} #{usage}")
      end
    end

    ##
    # Adds the command and block into the bot to process later
    # also sets up the command regex
    #
    # @param cmd [String] a command to add
    # @param block [Proc] the code to execute when +cmd+ is recieved
    
    def add_command cmd, &block
      @commands.append cmd unless @commands.include? cmd
      @cmd_hash[cmd.to_sym] = block

      # build up our regex (this regex should be fine, i guess :shrug:)
      @cmd_regex = /\A#{@prefix}(?<cmd>#{@commands.join('|')})\b(?<data>.*)/m
    end

    ##
    # What to do if we don't match anything
    #
    # @param block [Proc] a block to run when we don't match a command
    
    def if_not_found &block
      @not_found = block
    end

    ##
    # Starts loop to process any mentions, running command procs set up earlier
    
    def run_commands
      @streamer.user do |update|
        next unless update.kind_of? Mastodon::Notification and update.type == 'mention'

        # set up the status to strip html, if needed
        update.status.class
          .module_eval { alias_method :content, :strip } if @strip_html
        store_mention_data update.status

        # strip our username out of the status
        post = update.status.content.gsub(/@#{@username} /, '')

        # see if the post matches our regex, running the stored proc if it does
        matches = @cmd_regex.match(post)

        unless matches.nil?
          @cmd_hash[matches[:cmd].to_sym]
            .call(self,
                  matches[:data].strip,
                  update.status)
        else
          @not_found.call(self, update.status)
        end
      end
    end

    alias_method :run, :run_commands
  end
end
