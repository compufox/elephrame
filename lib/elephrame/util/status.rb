module Mastodon
  class Status
    alias_method :rcontent, :content
    
    ##
    # Strips all html tags out of +content+
    #
    # @return [String]
    
    def strip
      rcontent
        .gsub(/<\/p><p>/, "\n")
        .gsub(/<("[^"]*"|'[^']*'|[^'">])*>/, '')
        .gsub('&gt;', '>')
        .gsub('&lt;', '<')
        .gsub('&apos;', '\'')
        .gsub('&quot;', '"')
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
      
