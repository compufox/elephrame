module Elephrame
  class GenerativeBot < BaseBot
    include Elephrame::Streaming
    include Elephrame::Reply
    include Elephrame::Scheduler
    include Elephrame::Command

    attr_accessor :cw
    attr_reader :filter_words
    attr :filter,
         :filter_by,
         :following,
         :model,
         :char_limit,
         :retry_limit,
         :visibility

    backup_method :post, :actually_post

    def initialize(interval, options = {})
      require 'moo_ebooks'

      # initialize our botness
      super()

      # setup our various classes
      setup_streaming
      setup_scheduler interval
      setup_command

      # make an empty model, a default regex
      #  and fetch the max characters for posts (or 500 :shrug:)
      @model = Ebooks::Model.new
      @filter = /./
      @char_limit = @client.instance.max_toot_chars || 500
      @retry_limit = options[:retry_limit] || 10
      @cw = options[:cw] || 'markov post'
      @visibility = options[:visibility] || 'unlisted'

      # add our commands

      # !delete will delete the status it's in reply to
      add_command 'delete' do |bot, content, status|
        @client.destroy_status(status.in_reply_to_id) if @following.include? status.account.id
      end

      # !filter will add every word from the post into the word filter
      add_command 'filter' do |bot, content, status|
        if @following.include? status.account.id
          content.split.each do |word|
            filter << word
          end
        end
      end

      # set up a default for replying
      on_reply do |bot, status|
        text = @model.reply(status.content.gsub(/@.+?(@.+?)?\s/, ''),
                            limit: @char_limit)
        tries = 0

        while not bot.reply_with_mentions(text, spoiler: @cw) and
             tries < @retry_limit
          text = @model.reply(status.content.gsub(/@.+?(@.+?)?\s/, ''),
                              limit: @char_limit)
          tries += 1
        end
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
    # Adds a word into the filter list
    #
    # @param word [String]
    
    def filter<< word
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
      passed = @filter_by.call(text) unless @filter_by.nil?
      passed = text =~ @filter
      
      actually_post(text, **opts) if passed
    end

    alias_method :post, :filter_and_post
  end
end
