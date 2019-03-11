require_relative 'reply'
require_relative 'command'
require_relative 'interaction'
require_relative 'watcher'

module Elephrame
  module Streaming
    attr :streamer

    ##
    # Creates the stream client
    
    def setup_streaming
      stream_uri = @client.instance()
                     .attributes['urls']['streaming_api'].gsub(/^wss?/, 'https')
      @streamer = Mastodon::Streaming::Client.new(base_url: stream_uri,
                                                  bearer_token: ENV['TOKEN'])
    end

  end
end
