module Elephrame
  module TimelineWatcher
    attr :endpoint, :endpoint_arg

    def setup_watcher(timeline, arg = nil)

      @endpoint = format_tl(timeline)

      raise 'list or tag not supplied' if endpoint_needs_arg? and arg.nil?
      @endpoint_arg = arg

      # does some heavy lifting so the developer
      #  doesn't need to know the ID of the list
      @endpoint_arg = fetch_list_id(arg) if @endpoint == 'list'

      # in case the the argument contains an actual hash symbol
      @endpoint_arg.gsub!('#', '') if @endpoint =~ /tag/
    end
    
    def run_watcher &block
      @streamer.send(@endpoint,
                     @endpoint_arg) do |post|
        next if post.kind_of? Mastodon::Notification or
                post.kind_of? Mastodon::Streaming::DeletedStatus
        
        # this makes it so .content calls strip instead 
        post.class.module_eval { alias_method :content, :strip } if @strip_html
        
        block.call(self, post)
      end
    end

    alias_method :run, :run_watcher

    private
    
    def format_tl(tl)
      tl.gsub('home', 'user').gsub('public', 'firehose')
        .gsub(/(hash)?tag/, 'hashtag')
        .gsub('local ', 'local_')
    end

    def endpoint_needs_arg?
      @endpoint =~ /(list|hashtag)/
    end
  end
end
