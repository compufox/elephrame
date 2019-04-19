require_relative '../rest/rest'
require_relative '../streaming/streaming'
require_relative './tracery'
require_relative './generative'
require_relative '../bot'

module Elephrame
  module Bots
    
    ##
    # a bot that posts things on an interval but can also respond
    # to interactions
    #
    # requires on_* variables to be set before running, otherwise the bot
    # won't react to interactions
    
    class PeriodInteract < BaseBot
      include Elephrame::Streaming
      include Elephrame::Scheduler
      include Elephrame::AllInteractions

      ##
      # creates a new PeriodInteract bot
      #
      # @param intv [String] string specifying interval to post
      #
      # @return [Elephrame::Bots::PeriodInteract]
      
      def initialize intv
        super()
        
        setup_scheduler intv
        setup_streaming
      end

      ##
      # Runs the bot. requires a block for periodic post logic, but relies on
      # on_* functions for interaction logic. See Elephrame::AllInteractions
      # for more details.
      
      def run
        run_scheduled &Proc.new
        run_interact
      end
    end

    ##
    # a bot that posts things on an interval but can also respond
    # to interactions, providing a grammer object and a few helper 
    # methods to easily create bots with tracery.
    #
    # set on_reply before running, otherwise the bot
    # won't react to mentions
    
    class TraceryBot < BaseBot
      backup_method :post, :actually_post
      
      include Elephrame::Streaming
      include Elephrame::Scheduler
      include Elephrame::Reply
      include Elephrame::Trace

      ##
      # create a new TraceryBot
      # @param interval [String] a string representing the interval to post
      # @param dirs [Array<String>] an array of strings with paths to  directories
      #    containing tracery grammer rules
      # @return [Elephrame::Bots::TraceryBot]
      
      def initialize interval, *dirs
        super()

        # set up our bot stuff
        setup_scheduler interval
        setup_streaming
        setup_tracery dirs
      end

      ##
      # Runs the bot. requires a block for periodic post logic, but relies on
      # on_* functions for interaction logic. See Elephrame::AllInteractions
      # for more details.
      
      def run
        run_scheduled &Proc.new

        # if we have any logic for on_reply, we run that
        #  otherwise we go past it and wait for our scheduler to finish
        run_reply unless @on_reply.nil?
        @scheduler.join
      end
    end

    ##
    # A basic Ebooks bot template
    
    class EbooksBot < GenerativeBot
      attr :update_interval,
           :old_id,
           :scrape_filter
      
      PrivacyLevels = ['public', 'unlisted', 'private', 'direct']
      APILimit = 280
      RetryTime = '6m'
      
      ##
      # Creates a new Ebooks bot
      #
      # @param interval [String] how often should the bot post on it's own
      # @param opts [Hash] options for the bot
      # @option opt cw [String]
      # @option opt update_interval [String] how often to scrape new posts
      #        from the accounts the bot follows
      # @option opt retry_limit [Integer] the amount of times to retry
      #        generating a post
      # @option opt model_filename [String] path to a file where we 
      #        will save our backing ebooks model data
      # @option opt filter_filename [String] path to a file where we 
      #        will save our internal filtered words data      
      # @option opt visibility [String] the posting level the bot will default to
      # @option opt scrape_privacy [String] the highest privacy the bot should
      #        scrape for content
      
      def initialize(interval, opts = {})
        super

        # add our manual update command
        add_command 'update' do
          fetch_posts
        end

        # set some defaults for our internal vars
        level = PrivacyLevels.index(opts[:scrape_privacy]) || 0
        @scrape_filter = /(#{PrivacyLevels[0..level].join('|')})/
        @update_interval = opts[:update_interval] || '2d'

        # if we don't have what a newest post id then we fetch them
        #  for each account
        if @model_hash[:last_id].empty?
          @old_id = {}
          
          @following.each do |account|
            # get the newest post from this account and save the id
            newest_id = @client.statuses(account,
                                         exclude_reblogs: true,
                                         limit: 1).first.id
            @model_hash[:last_id][account] = newest_id
            @old_id[account] = newest_id
          end
        end

        # if our model's token are empty that means we have an empty model
        fetch_old_posts if @model_hash[:model].tokens.empty?
      end

      ##
      # Method to go and fetch all posts
      #  should be ran first
      
      def fetch_old_posts
        begin
          # init some vars to keep track of where we are
          api_calls = 1
          errored = false
          new_posts = { statuses: [],
                        mentions: [] }

          # for each account we're following
          @following.each do |account|
            # okay so
            #  we keep track of how many get requests we're doing and before
            #  the limit (300) we schedule for 5min and go on, saving what we got
            posts = @client.statuses(account,
                                     exclude_reblogs: true,
                                     limit: 40,
                                     max_id: @old_id[account])
            
            # while we still have posts and haven't gotten near the api limit
            while not posts.size.zero? and api_calls < APILimit
              posts.each do |post|
                
                # add the new post to our hash
                if post.visibility =~ @scrape_filter
                  new_posts = add_post_to_hash post, new_posts
                end
                
                # set our cached id to the latest post id
                @old_id[account] = post.id
              end
              
              # fetch more posts
              posts = @client.statuses(account,
                                       exclude_reblogs: true,
                                       limit: 40,
                                       max_id: @old_id[account])
              api_calls += 1
            end
            
            break if api_calls >= APILimit
          end
          
        rescue Mastodon::Error::TooManyRequests
          errored = true
          
        ensure
          # consume our posts, and then save our model
          @model_hash[:model].consume! new_posts
          save_file(@model_filename,
                    @model_hash.collect {|key, value| value.to_hash }.to_yaml)

          # if we have more than our limit of api calls
          #  or we errored out that means we need to check again
          if api_calls >= APILimit or errored 
            @scheduler.in RetryTime do
              fetch_old_posts
            end
          end
        end
      end
      
      ##
      # Fetch posts from the accounts the bot follows
      
      def fetch_new_posts
        begin
          # set up some vars for tracking our progress
          added_posts = { statuses: [],
                          mentions: [] }
          api_calls = 1
          errored = false

          # for each account we're following
          @following.each do |account|
            # get 40 posts at a time, where we left off
            posts = @client.statuses(account,
                                     exclude_reblogs: true,
                                     limit: 40,
                                     since_id: @model_hash[:last_id][account])

            # while we have posts to process and we haven't
            #  gotten near the api limit
            while not posts.size.zero? and api_calls < APILimit
              posts.reverse_each do |post|
                # save our post id for next loop
                @model_hash[:last_id][account] = post.id

                # if the post matches our set visibility we add it to our hash
                if posts.visibility =~ @scrape_filter
                  added_posts = add_post_to_hash post, added_posts
                end
              end

              # fetch more posts
              posts = @client.statuses(account,
                                       exclude_reblogs: true,
                                       limit: 40,
                                       since_id: @model_hash[:last_id][account])
              api_calls += 1
            end

            # in case we hit our api limit between calls
            break if api_calls >= APILimit
          end
          
        rescue Mastodon::Errors::TooManyRequests
          # if we've hit here then we've errored out
          errored = true
          
        ensure
          # consume our new posts, and add them to our original hash
          @model_hash[:model].consume! added_posts
          
          if api_calls >= APILimit or errored
            @scheduler.in RetryTime do
              fetch_new_posts
            end
          end
          
          # then we save 
          save_file(@model_filename,
                    @model_hash.collect {|key, value| value.to_hash }.to_yaml)
        end
      end

      ##
      # Run the Ebooks bot
      
      def run
        # set up our scheduler to scrape posts
        @scheduler.repeat @update_interval do
          fetch_new_posts
        end

        # call generativebot's run method
        super
      end

      private

      ##
      # adds a post into the +post_hash+ hash
      #  makes sure it gets put under the appropriate key
      #
      # @param post [Mastodon::Status]
      
      def add_post_to_hash post, hash
        # make sure we strip out the html crap
        post.class
          .module_eval { alias_method :content, :strip } if @strip_html
        
        # decide which array the post should go into, based
        #  on if it's a reply or not
        # also make sure to strip out any account names
        if post.in_reply_to_id.nil? or post.mentions.size.zero?
          hash[:statuses] << post.content
        else
          hash[:mentions] << post.content.gsub(/@.+?(@.+?)?\s/, '')
        end

        hash
      end
    end

    ##
    # A more general purpose markov bot. Reads in data from a supplied source
    
    class MarkovBot < GenerativeBot

      ##
      # Creates a new Ebooks bot
      #
      # @param interval [String] how often should the bot post on it's own
      # @param opts [Hash] options for the bot
      # @option opt cw [String]
      # @option opt retry_limit [Integer] the amount of times to retry
      #        generating a post
      # @option opt model_filename [String] path to a file where we 
      #        will save our backing ebooks model data
      # @option opt filter_filename [String] path to a file where we 
      #        will save our internal filtered words data
      # @option opt visibility [String] the posting level the bot will default to
      # @option opt 
      
      def initialize(interval, options = {})
        super

        # initialize the model to contain the specified source text
      end
    end
  end
end








