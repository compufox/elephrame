module Elephrame
  module TimelineWatcher
    
    attr :endpoint, :endpoint_arg

    def setup_watcher(timeline, arg = nil)

      @endpoint = timeline

      if endpoint_needs_arg?
        raise "Must supply name of #{timeline}" if arg.nil?

        # does some heavy lifting so the developer
        #  doesn't need to know the ID of the list
        if timeline == 'list'
          @endpoint_arg = fetch_list_id(arg)
        else
          @endpoint_arg = arg
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
