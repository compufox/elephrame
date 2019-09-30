require 'tracery'
require 'json'

module Elephrame
  module Trace
    include Tracery

    # grammar is a hash { FILENAME => TRACERY RULES }
    attr_accessor :grammar

    ##
    # loads all of our tracery files into our +files+ hash
    # if a file is named 'default' then we load that into +grammar+
    #
    # @param dirs [String] path to the directory containing the tracery rules
    
    def setup_tracery *dirs
      
      @grammar = {}

      dirs.each do |directory|
        Dir.open(directory) do |dir|
          dir.each do |file|
            # skip our current and parent dir
            next if file =~ /^\.\.?$/
            
            # read the rule file into the files hash
            @grammar[file.split('.').first] =
              createGrammar(JSON.parse(File.read("#{directory}/#{file}")))
          end
        end
      end
        
      # go ahead and makes a default mention-handler
      #  if we have a reply rule file
      unless @grammar['reply'].nil?
        on_reply do |bot|
          bot.reply_with_mentions('#default#', rules: 'reply')
        end
      end
    end

    
    ##
    # a shortcut fuction for expanding text with tracery before posting
    #
    # @param text [String] the tracery text to expand before posting
    # @param options [Hash] a hash of arguments to pass to post
    # @option options rules [String] the grammar rules to load
    # @option options visibility [String] visibility level
    # @option options spoiler [String] text to use as content warning
    # @option options reply_id [String] id of post to reply to
    # @option options hide_media [Bool] should we hide media?
    # @option options media [Array<String>] array of file paths
    
    def expand_and_post(text, *options)
      opts = Hash[*options]
      rules = opts.fetch(:rules, 'default')
      actually_post(@grammar[rules].flatten(text),
                    **opts.reject {|k|
                      k == :rules
                    })
    end

    alias_method :post, :expand_and_post
  end
end
