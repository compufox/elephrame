require_relative 'reply'
require_relative 'command'
require_relative 'interaction'

module Elephrame
  module Streaming
    attr :streamer

    ##
    # Creates the stream client
    
    def setup_streaming
      @streamer = Mastodon::Streaming::Client.new(base_url: ENV['INSTANCE'],
                                                  bearer_token: ENV['TOKEN'])
    end

  end
end
