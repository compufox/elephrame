module Elephrame
  module Scheduler
    attr :scheduler, :interval
    attr_reader :schedule
    
    def setup_scheduler intv
      require 'rufus-scheduler'
      
      
      @interval = intv
      @scheduler = Rufus::Scheduler.new
    end
    
    def run_scheduled
      @scheduler.repeat @interval do |j|
        @schedule = j
        yield(self)
      end
      @scheduler.join unless not @streamer.nil?
    end

    alias_method :run, :run_scheduled
  end
end
