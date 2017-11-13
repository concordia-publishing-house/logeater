module Logeater
  class Eventfile
    attr_reader :events, :filename
    attr_accessor :show_progress
    alias :show_progress? :show_progress

    def initialize(events)
      @events = events
      @filename = "events_#{events.count}"
    end

    def each_line
      events.pluck(:original).each do |event|
        yield event
      end
    end

  end
end
