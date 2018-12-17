module Elephrame
  module Command
    include Elephrame::Reply
    
    attr_reader :commands, :prefix
    attr :cmd_hash, :cmd_regex, :not_found

    ##
    # Initializes the +commands+ array, +cmd_hash+ 
    #
    # @param prefix [String] sets the command prefix, defaults to '!'
    # @param usage [String] the response to the help command
    # 
    
    def setup_command(prefix = '!', usage = nil)
        @commands = []
        @cmd_hash = {}
        
        set_prefix prefix
        set_help usage unless usage.nil?
    end

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
        bot.reply("#{usage}")
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
    #
    # If a block is passed to this function it gets ran when no commands
    # get matched. Otherwise the framework checks if +not_found+ exists
    # and runs it
    
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
          
          if block_given?
            yield(self, update.status)
          else
            @not_found.call(self, update.status) unless @not_found.nil?
          end
          
        end
      end
    end

    alias_method :run, :run_commands
  end
end
