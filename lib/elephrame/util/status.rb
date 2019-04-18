require 'htmlentities'

module Mastodon
  class Status
    alias_method :rcontent, :content

    Decoder = HTMLEntities.new
    
    ##
    # Strips all html tags out of +content+
    #
    # @return [String]
    
    def strip
      Decoder.decode(rcontent
                       .gsub(/<\/p><p>/, "\n")
                       .gsub(/<("[^"]*"|'[^']*'|[^'">])*>/, ''))
    end

    ##
    # Returns whether or not the status is a reblogged status
    #
    # @return [Boolean]
    
    def is_reblog?
      not @attributes['reblog'].nil?
    end
  end
end
      
