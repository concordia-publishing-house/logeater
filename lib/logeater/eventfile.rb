module Logeater
  class Eventfile
    attr_reader :events, :filename
    attr_accessor :show_progress
    alias :show_progress? :show_progress

    def initialize(events)
      @events = events
      @filename = "events_#{timestamp}"
    end

    def each_line
      events.find_each do |event|
        yield event.logger_line
        event.touch :processed_at
      end
    end

  private

    def timestamp
      @timestamp ||= Time.now.strftime "%Y%m%d%H%M%S.%L"
    end

  end
end
