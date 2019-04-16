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
      # @param tracery_dir [String] a string with the path to the directory
      #    containing all of the tracery grammer rules.
      # @return [Elephrame::Bots::TraceryBot]
      
      def initialize interval, tracery_dir
        super()

        # set up our bot stuff
        setup_scheduler interval
        setup_streaming
        setup_tracery tracery_dir
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
           :old_id

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
      # @option opt filename [String] path to a file where we will save our
      #        backing ebooks model data
      
      def initialize(interval, opts = {})
        super
        
        add_command 'update' do
          fetch_posts
        end

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
        
        fetch_old_posts if @model_hash[:statuses].empty?
      end

      ##
      # Method to go and fetch all posts
      #  should be ran first
      
      def fetch_old_posts
        puts "fetching old posts" if ENV['DEBUG']
        
        begin
          api_calls = 1
          errored = false
          
          @following.each do |account|
            # okay so
            #  we keep track of how many get requests we're doing and before
            #  the limit (300) we schedule for 5min and go on, saving what we got
            posts = @client.statuses(account,
                                     exclude_reblogs: true,
                                     limit: 40,
                                     max_id: @old_id[account])
            processed_count = 0 if ENV['DEBUG']
            
            # while we still have posts and haven't gotten near the api limit
            while not posts.size.zero? and api_calls < 280
              posts.each do |post|
                # add the new post to our hash
                add_post_to_hash post
                
                # set our cached id to the latest post id
                @old_id[account] = post.id
                processed_count += 1 if ENV['DEBUG']
              end
              
              puts "processed #{processed_count} posts...fetching more" if ENV['DEBUG']
              
              # fetch more posts
              posts = @client.statuses(account,
                                       exclude_reblogs: true,
                                       limit: 40,
                                       max_id: @old_id[account])
              api_calls += 1
            end
            
            break if api_calls >= 280
          end
          
        rescue Mastodon::Error::TooManyRequests
          puts "hit the api limit, saving what we have and scheduling to continue" if ENV['DEBUG']
          errored = true
          
        ensure
          save_file @filename
          @model.consume! @model_hash

          if api_calls >= 280 or errored 
            @scheduler.in '5m' do
              fetch_old_posts
            end
          end
        end
      end
      
      ##
      # Fetch posts from the accounts the bot follows
      
      def fetch_new_posts
        begin
          added_posts = { statuses: [],
                          mentions: [] }
          api_calls = 1
          errored = false
          
          @following.each do |account|
            
            posts = @client.statuses(account,
                                     exclude_reblogs: true,
                                     limit: 40,
                                     since_id: @model_hash[:last_id][account])
            
            while not posts.size.zero? and api_calls < 280
              posts.reverse_each do |post|
                @model_hash[:last_id][account] = post.id
                
                post.class
                  .module_eval { alias_method :content, :strip } if @strip_html
                
                
                if post.in_reply_to_id.nil?
                  added_posts[:statuses] << post.content
                else
                  added_posts[:mentions] << post.content.gsub(/@.+?(@.+?)?\s/, '')
                end
              end
              
              posts = @client.statuses(account,
                                       exclude_reblogs: true,
                                       limit: 40,
                                       since_id: @model_hash[:last_id][account])
              api_calls += 1
            end
            
            break if api_calls >= 280
          end
          
        rescue Mastodon::Errors::TooManyRequests
          errored = true
          
        ensure
          # consume our new posts, and add them to our original hash
          @model.consume! added_posts
          @model_hash.merge! added_posts do |key, orig_val, new_val|
            if key == :statuses or key == :mentions
              new_val.each do |value|
                orig_val << value
              end
            end
          end
          
          if api_calls >= 280 or errored
            @scheduler.in '5m' do
              fetch_new_posts
            end
          end
          
          # then we save 
          save_file @filename
        end
      end

      ##
      # Run the Ebooks bot
      
      def run
        # set up our scheduler to scrape posts
        @scheduler.repeat @update_interval do
          fetch_posts
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
      
      def add_post_to_hash post
        # make sure we strip out the html crap
        post.class
          .module_eval { alias_method :content, :strip } if @strip_html
        
        # decide which array the post should go into, based
        #  on if it's a reply or not
        # also make sure to strip out any account names
        if post.in_reply_to_id.nil?
          @model_hash[:statuses] << post.content
        else
          @model_hash[:mentions] << post.content.gsub(/@.+?(@.+?)?\s/, '')
        end

        nil
      end
    end
    
  end
end
