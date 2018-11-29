module Mastodon
  class Status
    alias_method :rcontent, :content
    
    ##
    # Strips all html tags out of +content+
    #
    # @return [String]
    
    def strip
      rcontent.gsub(/<\/p><p>/, "\n")
        .gsub(/<("[^"]*"|'[^']*'|[^'">])*>/, '')
    end
  end
end
      
