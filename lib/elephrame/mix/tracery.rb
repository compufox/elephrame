require 'tracery'
require 'json'

module Elephrame
  module Trace
    include Tracery
    
    # files is hash { FILENAME => FILECONTENT }
    attr_reader :files
    attr_writer :grammar

    ##
    # loads all of our tracery files into our +files+ hash
    # if a file is named 'default' then we load that into +grammar+
    #
    # @param dir [String] path to the directory containing the tracery rules
    
    def setup_tracery dir_path
      raise "Provided path not a directory" unless Dir.exist?(dir_path)

      @files = {}
      Dir.open(dir_path) do |dir|
        dir.each do |file|
          # skip our current and parent dir
          next if file =~ /^\.\.?$/

          # read the rule file into the files hash
          @files[file.split('.').first] =
            JSON.parse(File.read("#{dir_path}/#{file}"))
        end
      end

      @grammar = createGrammar(@files['default']) unless @files['default'].nil?
    end

    
    ##
    # a shortcut fuction for expanding text with tracery before posting
    #
    # @param text [String] the tracery text to expand before posting
    # @param options [Hash] a hash of arguments to pass to post
    
    def post_and_expand(text, *options)
      opts = Hash[*options]
      actually_post(@grammar.flatten(text), **opts)
    end

    alias_method :post, :post_and_expand
  end
end
