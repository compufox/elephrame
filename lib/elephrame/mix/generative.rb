module Elephrame
  module Bots
    class GenerativeBot < BaseBot
      include Elephrame::Streaming
      include Elephrame::Reply
      include Elephrame::Scheduler
      include Elephrame::Command
      
      attr_accessor :cw
      attr :filter,
           :filter_words,
           :filter_by,
           :following,
           :model,
           :char_limit,
           :retry_limit,
           :visibility,
           :model_hash,
           :model_filename,
           :filter_filename
      
      backup_method :post, :actually_post
      SavedFileName = 'model.yml'
      SavedFilterFileName = 'filter.yml'
      
      def initialize(interval, options = {})
        require 'moo_ebooks'
        require 'yaml'
        
        # initialize our botness
        super()
        
        # setup our various classes
        setup_streaming
        setup_scheduler interval
        setup_command
        
        # set some defaults and initialize some vars
        @model_hash = { model: Ebooks::Model.new,
                        last_id:  {} }
        @filter = /./
        @filter_words = []
        @following = []
        @char_limit = @client.instance.max_toot_chars || 500
        @retry_limit = options[:retry_limit] || 10
        @cw = options[:cw] || 'markov post'
        @visibility = options[:visibility] || 'unlisted'
        @model_filename = options[:model_filename] || SavedFileName
        @filter_filename = options[:filter_filename] || SavedFilterFileName
        
        # load our model if it exists
        if File.exists? @model_filename
          values = load_file(@model_filename)
          @model_hash[:model] = Ebooks::Model.from_hash(values.first)
          @model_hash[:last_id] = values.last
        end
        
        @filter_words = load_file(@filter_filename) if File.exists? @filter_filename
        
        # add our commands
        #
        # !delete will delete the status it's in reply to
        add_command 'delete' do |bot, content, status|
          if @following.include? status.account.id
            @client.destroy_status(status.in_reply_to_id)
            bot.reply('status deleted')
          end
        end
        
        # !filter will add every word from the post into the word filter
        add_command 'filter' do |bot, content, status|
          if @following.include? status.account.id
            content.split.each do |word|
              add_filter_word word
            end
            save_file @filter_filename, @filter_words.to_yaml
            bot.reply("'#{content}' added to internal filter")
          end
        end

        # add a help command that explains the other commands
        add_command 'help' do |bot|
          if @following.include? status.account.id
            bot.reply(HelpMessage)
          end
        end
        
        # set up a default for replying
        on_reply do |bot, status|
          # retry our status creation until we get something that
          #  passes our filters
          @retry_limit.times do
            text = @model_hash[:model].reply(status
                                               .content
                                               .gsub(/@.+?(@.+?)?\s/, ''),
                                             @char_limit)
            break unless bot.reply_with_mentions(text,
                                                 spoiler: @cw).nil?
          end
        end
        
        # get our own account id and save the ids of the accounts
        #  we're following
        acct_id = @client.verify_credentials.id
        @client.following(acct_id).each do |account|
          @following << account.id
        end
      end
      
      ##
      # Runs the bot
      
      def run
        # see scheduler.rb
        run_scheduled do |bot|
          @retry_limit.times do
            text = @model_hash[:model].update(@char_limit)
            break unless bot.post(text,
                                  spoiler: @cw,
                                  visibility: @visibility).nil?
          end
        end
        
        # we do this because run_commands accepts a block that
        #  will run when it doesn't find a command in a mention
        #  this should work. :shrug:
        run_commands do |bot, status|
          @on_reply.call(bot, status)
        end
      end
      
      ##
      # loads a yaml file containing our model data
      #
      # @param filename [String] file to read in from
      
      def load_file filename
        YAML.load_file(filename)
      end
      
      ##
      # Saves a yaml file containing our model data
      #
      # @param filename [String] file to write out to
      
      def save_file filename, data
        File.write(filename, data)
      end
      
      ##
      # Sets the filter regex
      #  if arg is a string array, 'or's the strings together
      #  if it's a regexp it just sets it to the value
      #
      # @param arg [Array<String>,String,Regexp]
      
      def filter= arg
        arg = arg.join('|') if arg.kind_of? Array
        arg = /#{arg}/ unless arg.kind_of? Regexp
        @filter = arg
      end
      
      ##
      # Returns a string representing all of the current
      #  words being checked in the filter
      #
      # @returns [String] comma separated list of all filter words
      
      def filter_words
        @filter_words.join(', ')
      end
      
      ##
      # Adds a word into the filter list
      #
      # @param word [String]
      
      def add_filter_word(word)
        @filter_words << word
        filter = @filter_words
      end
      
      ##
      # Accepts a block to check the post against before posting
      #
      # @param block [Proc]
      
      def filter_by &block
        @filter_by = block
      end
      
      ##
      # Checks the proposed post against the filters
      #  only posts if the text passes the filters
      #
      # @param text [String] the tracery text to expand before posting
      # @param options [Hash] a hash of arguments to pass to post
      # @option options rules [String] the grammar rules to load
      # @option options visibility [String] visibility level
      # @option options spoiler [String] text to use as content warning
      # @option options reply_id [String] id of post to reply to
      # @option options hide_media [Bool] should we hide media?
      # @option options media [Array<String>] array of file paths
      
      def filter_and_post(text, *options)
        opts = Hash[*options]
        
        # default passed to false and then see if
        #  the supplied text gets through our filters
        passed = false
        passed = text =~ @filter 
        passed = @filter_by.call(text) unless @filter_by.nil?
        
        actually_post(text, **opts) if passed
      end
      
      alias_method :post, :filter_and_post
    end
  end
end
