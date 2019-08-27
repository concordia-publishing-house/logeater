require "active_record"

module Logeater
  class Event < ActiveRecord::Base
    self.table_name = "events"

    def self.since(timestamp)
      where(arel_table[:received_at].gteq(timestamp))
    end

    def self.processed
      where.not(processed_at: nil)
    end

    def self.unprocessed
      where(processed_at: nil)
    end

    def logger_line
      "#{severity_id}, [#{timestamp}]  #{severity_label} -- : #{message}"
    end

    def severity_id
      SEVERITY[log_level][:id]
    end

    def severity_label
      SEVERITY[log_level][:label]
    end

    def timestamp
      emitted_at.strftime("%FT%T.%6N")
    end

  private

    def log_level
      LOG_LEVELS.fetch(priority % 8)
    end

    LOG_LEVELS = {
      0 => Logger::FATAL,   # Emergency: system is unusable
      1 => Logger::FATAL,   # Alert: action must be taken immediately
      2 => Logger::FATAL,   # Critical: critical conditions
      3 => Logger::ERROR,   # Error: error conditions
      4 => Logger::WARN,    # Warning: warning conditions
      5 => Logger::INFO,    # Notice: normal but significant condition
      6 => Logger::INFO,    # Informational: informational messages
      7 => Logger::DEBUG    # Debug: debug-level messages
    }.freeze

    SEVERITY = {
      Logger::FATAL => { id: "F", label: "FATAL" },
      Logger::ERROR => { id: "E", label: "ERROR" },
      Logger::WARN => { id: "W", label: "WARN" },
      Logger::INFO => { id: "I", label: "INFO" },
      Logger::DEBUG => { id: "D", label: "DEBUG" }
    }.freeze

  end
end
