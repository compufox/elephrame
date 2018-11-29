module Elephrame
  module Scheduler
    attr :scheduler, :interval
    attr_reader :schedule

    ##
    # Creates a new scheduler
    #
    # @param intv [String] string specifying interval to post
    def setup_scheduler intv
      require 'rufus-scheduler'
      
      
      @interval = intv
      @scheduler = Rufus::Scheduler.new
    end

    ##
    # Runs the schedule. Requires a block to be passed to it.
    
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
