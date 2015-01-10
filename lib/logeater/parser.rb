require "addressable/uri"
require "active_support/inflector"

module Logeater
  class Parser
    
    class Error < ::ArgumentError
      def initialize(message, line)
        super "ERROR: #{message}\nDETAIL: #{line.inspect}"
      end
    end
    
    LINE_MATCHER = /^
      [A-Z],\s
    \[(?<timestamp>[^\s\]]+)(?:\s[^\]]*)?\]\s+
      (?<log_level>[A-Z]+)\s+\-\-\s:\s+
    \[(?<subdomain>[^\]]+)\]\s
    \[(?<uuid>[\w\-]{36})\]\s+
      (?<message>.*)
    $/x.freeze
    
    TIMESTAMP_MATCHER = /
      (?<year>\d\d\d\d)\-
      (?<month>\d\d)\-
      (?<day>\d\d)T
      (?<hours>\d\d):
      (?<minutes>\d\d):
      (?<seconds>\d\d(?:\.\d+))
    /x.freeze
    
    HTTP_VERBS = %w{DELETE GET HEAD OPTIONS PATCH POST PUT}.freeze
    
    REQUEST_STARTED_MATCHER = /^
      Started\s
      (?<http_method>[A-Z]+)\s
     "(?<path>[^"]+)"\sfor\s
      (?<remote_ip>[\d\.]+)
    /x.freeze
    
    REQUEST_CONTROLLER_MATCHER = /^
      Processing\sby\s
      (?<controller>[A-Za-z0-9]+)\#
      (?<action>[a-z_0-9]+)\sas\s
      (?<format>.*)\b
    /x.freeze
    
    REQUEST_PARAMETERS_MATCHER = /^
      Parameters:\s
      (?<params>\{.*\})
    $/x.freeze
    
    REQUEST_COMPLETED_MATCHER = /^
      Completed\s
      (?<http_status>\d\d\d)\s
      (?<http_response>.*)\sin\s
      (?<duration>[\d\.]+)(?<units>ms)\s
    /x.freeze # optional: (Views: 0.1ms | ActiveRecord: 50.0ms)
    
    def parse!(line)
      match = line.match(LINE_MATCHER)
      raise Error.new("Unmatched line", line) unless match
      
      timestamp = match["timestamp"]
      time = timestamp.match(TIMESTAMP_MATCHER)
      raise Error.new("Malformated timestamp", timestamp) unless time
      time = Time.new(*time.captures[0...-1], BigDecimal.new(time["seconds"]))
      
      message = match["message"]
      type = identify_message(message)
      
      { timestamp: time,
        log_level: match["log_level"],
        subdomain: match["subdomain"],
        uuid: match["uuid"],
        type: type,
        message: message }.merge(
        custom_attributes_for(type, message))
    end
    
    def identify_message(message)
      return :request_started if message =~ /^Started (#{HTTP_VERBS.join("|")})/
      return :request_controller if message.start_with? "Processing by "
      return :request_params if message.start_with? "Parameters: "
      return :request_completed if message =~ /^Completed \d\d\d/
      :generic
    end
    
    def custom_attributes_for(type, message)
      attributes = send :"parse_#{type}_message", message
      unless attributes
        log "Unable to parse message identified as #{type.inspect}: #{message.inspect}"
        return {}
      end
      attributes
    end
    
    def parse_generic_message(message)
      {}
    end
    
    def parse_request_started_message(message)
      match = message.match(REQUEST_STARTED_MATCHER)
      return unless match
      uri = Addressable::URI.parse(match["path"])
      
      { http_method: match["http_method"],
        path: uri.path,
        remote_ip: match["remote_ip"] }
    end
    
    def parse_request_controller_message(message)
      match = message.match(REQUEST_CONTROLLER_MATCHER)
      return unless match
      
      { controller: match["controller"].underscore,
        action: match["action"],
        format: match["format"] }
    end
    
    def parse_request_params_message(message)
      match = message.match(REQUEST_PARAMETERS_MATCHER)
      return unless match
      
      { params: eval(match["params"]) } # <-- dangerous!
    end
    
    def parse_request_completed_message(message)
      match = message.match(REQUEST_COMPLETED_MATCHER)
      return unless match
      
      { http_status: match["http_status"].to_i,
        http_response: match["http_response"],
        duration: match["duration"].to_i }
    end
    
    
    
    def log(statement)
      puts "\e[33m#{statement}\e[0m"
    end
    
  end
end
