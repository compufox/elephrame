module Elephrame
  module TimelineWatcher
    
    attr :endpoint, :endpoint_arg

    def setup_watcher(timeline, args = nil)

      @endpoint = timeline

      if endpoint_needs_arg?
        raise "Must supply name of #{timeline}" if args.nil?

        if timeline == 'list'
          @endpoint_arg = @client.lists.collect { |l|
            return l.id if l.title == args
          }
        else
          @endpoint_arg = args
        end
      end
      
    end
    
    def run_watcher &block
      @streamer.send(@endpoint,
                     @endpoint_arg if endpoint_needs_arg?) do |post|
        next if post.kind_of? Mastodon::Notification
        block.call(self, post)
      end
    end

    alias_method :run, :run_watcher

    private

    def endpoint_needs_arg?
      @endpoint =~ /(list|hashtag)/
    end
  end
end
