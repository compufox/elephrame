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
    
    class Ebooks < GenerativeBot
      attr :update_interval,
           :last_id,
           :fetch_count

      ##
      # Creates a new Ebooks bot
      #
      # @param interval [String] how often should the bot post on it's own
      # @param opts [Hash] options for the bot
      # @option opt cw [String]
      # @option opt fetch_count [Integer] the amount of posts to fetch
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

        @last_id = {}

        initial_fetch if @model_hash[:statuses].empty?
      end

      ##
      # Method to go and fetch all posts
      #  should be ran first
      
      def initial_fetch
        @following.each do |account|
          # get the newest post from this account and save the id
          newest_id = @client.statuses(account,
                                       exclude_reblogs: true
                                       limit: 1)
          @last_id[account] = newest_id
          
          posts = @client.statuses(account,
                                   exclude_reblogs: true,
                                   limit: @fetch_count,
                                   max_id: newest_id)

          # while we still have posts
          while not posts.size.zero?
            posts.each do |post|
              # add the new post to our hash
              add_post_to_hash post
              
              # set our cached id to the latest post id
              newest_id = post.id
            end

            # fetch more posts
            posts = @client.statuses(account,
                                     exclude_reblogs: true,
                                     limit: @fetch_count,
                                     max_id: newest_id)
          end
        end
        save_file @filename
        @model.consume! @model_hash
      end
      
      ##
      # Fetch posts from the accounts the bot follows
      
      def fetch_posts
        added_posts = { statuses: [],
                        mentions: [] }
        @following.each do |account|

          posts = @client.statuses(account,
                                   exclude_reblogs: true,
                                   limit: @fetch_count,
                                   since_id: @last_id[account])
          while not posts.size.zero?
          
            posts.each do |post|
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
                                     limit: @fetch_count,
                                     since_id: @last_id[account])
          end
        end

        # consume our new posts, and add them to our original hash
        @model.consume! added_posts
        @model_hash.merge! added_posts do |key, orig_val, new_val|
          new_val.each do |value|
            orig_val << value
          end
        end

        # then we save 
        save_file @filename
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
