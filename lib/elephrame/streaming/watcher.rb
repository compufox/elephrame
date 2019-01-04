module Elephrame
  module TimelineWatcher
    LocalEndpoint = 'public/local'
    ListEndpoint  = 'list?list='

    attr :endpoint

    def setup_watcher(timeline, args = nil)
      
      case timeline

      when 'public'
        @endpoint = 'public'

      when 'home'
        @endpoint = 'user'

      when 'local'
        @endpoint = LocalEndpoint

      when 'list'
        raise 'list not specified' if args.nil?
        @endpoint = ListEndpoint + URI::encode(args)

      when 'tag'
        raise 'tag not specified' if args.nil?
        @endpoint = 'hashtag'

      end
      
    end
    
    def run_watcher &block
      
    end

    alias_method :run, :run_watcher
  end
end
