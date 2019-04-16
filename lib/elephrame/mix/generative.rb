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
           :filename
      
      backup_method :post, :actually_post
      SavedFileName = 'model.yml'
      
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
        @model = Ebooks::Model.new
        @model_hash = { statuses: [],
                        mentions: [] }
        @filter = /./
        @following = []
        @char_limit = @client.instance.max_toot_chars || 500
        @retry_limit = options[:retry_limit] || 10
        @cw = options[:cw] || 'markov post'
        @visibility = options[:visibility] || 'unlisted'
        @filename = options[:filename] || SavedFileName
        
        # load our hash if it exists
        if File.exists? @filename
          load_file @filename
        end
        
        # add our commands
        #
        # !delete will delete the status it's in reply to
        add_command 'delete' do |bot, content, status|
          @client.destroy_status(status.in_reply_to_id) if @following.include? status.account.id
        end
        
        # !filter will add every word from the post into the word filter
        add_command 'filter' do |bot, content, status|
          if @following.include? status.account.id
            content.split.each do |word|
              add_filter_word word
            end
          end
        end
        
        # set up a default for replying
        on_reply do |bot, status|
          text = @model.reply(status.content.gsub(/@.+?(@.+?)?\s/, ''),
                              limit: @char_limit)
          tries = 0
          
          # retry our status creation until we get something that
          #  passes our filters
          while not bot.reply_with_mentions(text, spoiler: @cw) and
               tries < @retry_limit
            text = @model.reply(status.content.gsub(/@.+?(@.+?)?\s/, ''),
                                limit: @char_limit)
            tries += 1
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
          text = @model.update(limit: @char_limit)
          tries = 0
          
          while not bot.post(text,
                             spoiler: @cw,
                             visibility: @visibility) and
               tries < @retry_limit
            text = @model.update(limit: @char_limit)
            tries += 1
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
        @model_hash = YAML.load_file(filename)
        @model.consume!(@model_hash)
      end
      
      ##
      # Saves a yaml file containing our model data
      #
      # @param filename [String] file to write out to
      
      def save_file filename
        File.write(filename, @model_hash.to_yaml)
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
      
      def filter_and_post(text, *opts)
        
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
