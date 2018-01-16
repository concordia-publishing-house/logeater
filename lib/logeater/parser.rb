require "addressable/uri"
require "active_support/inflector"
require "logeater/params_parser"
require "logeater/parser_errors"

module Logeater
  class Parser


    LINE_MATCHER = /^
      [A-Z],\s
    \[(?<timestamp>[^\s\]]+)(?:\s[^\]]*)?\]\s+
      (?<log_level>[A-Z]+)\s+\-\-\s:\s+
      (?<message>.*)
    $/x.freeze

    REQUEST_LINE_MATCHER = /^
    \[(?<subdomain>[^\]]+)\]\s
    \[(?<uuid>[\w\-]{36})\]\s+
 (?:\[(?:guest|user\.(?<user_id>\d+)(?<tester_bar>:cph)?|(?<email>.+@[^\]]+))\]\s+)?
      (?<message>.*)
    $/x.freeze

    REQUEST_STARTED_MATCHER = /^
      Started\s
      (?<http_method>[A-Z]+)\s
     "(?<path>[^"]+)"\sfor\s
      (?<remote_ip>[\d\.]+)
    /x.freeze

    REQUEST_CONTROLLER_MATCHER = /^
      Processing\sby\s
      (?<controller>[A-Za-z0-9:]+)\#
      (?<action>[a-z_0-9]+)\sas\s
      (?<format>.*)
    /x.freeze

    REQUEST_PARAMETERS_MATCHER = /^
      Parameters:\s
      (?<params>\{.*\})
    $/x.freeze

    REQUEST_COMPLETED_MATCHER = /^
      Completed\s
      (?<http_status>\d\d\d)\s
      (?:(?<http_response>.*)\s)?in\s
      (?<duration>[\d\.]+)(?<units>ms)\b
    /x.freeze # optional: (Views: 0.1ms | ActiveRecord: 50.0ms)

    def parse!(line)
      match = line.match LINE_MATCHER
      raise UnmatchedLine.new(line) unless match

      result = {
        type: :generic,
        timestamp: match["timestamp"],
        log_level: match["log_level"],
        message: match["message"]
      }.merge(
        parse_message(match["message"]))
    end

    def parse_message(message)
      match = message.match REQUEST_LINE_MATCHER
      return {} unless match

      message = match["message"]

      { subdomain: match["subdomain"],
        uuid: match["uuid"],
        type: :request_line,
        user_id: user_id_for(match),
        tester_bar: !!match["tester_bar"],
        message: message
      }.merge(
        parse_message_extra(message))
    end

    def parse_message_extra(message)
      match = message.match(REQUEST_STARTED_MATCHER)
      return parse_request_started_message(match) if match

      match = message.match(REQUEST_CONTROLLER_MATCHER)
      return parse_request_controller_message(match) if match

      match = message.match(REQUEST_PARAMETERS_MATCHER)
      return parse_request_params_message(match) if match

      match = message.match(REQUEST_COMPLETED_MATCHER)
      return parse_request_completed_message(match) if match

      {}
    end

    def parse_request_started_message(match)
      { type: :request_started,
        http_method: match["http_method"],
        path: parsed_uri[match["path"]],
        remote_ip: match["remote_ip"] }
    end

    def parse_request_controller_message(match)
      { type: :request_controller,
        controller: normalized_controller_name[match["controller"]],
        action: match["action"],
        format: match["format"] }
    end

    def parse_request_params_message(match)
      { type: :request_params,
        params: ParamsParser.new(match["params"]).parse! }
    rescue Logeater::Parser::MalformedParameters
      log "Unable to parse parameters: #{match["params"].inspect}"
      { params: match["params"] }
    end

    def parse_request_completed_message(match)
      { type: :request_completed,
        http_status: match["http_status"].to_i,
        http_response: match["http_response"],
        duration: match["duration"].to_i }
    end

    def user_id_for(match)
      return match["user_id"].to_i if match["user_id"]
      return match["email"] if match["email"]
      nil
    end



    def log(statement)
      $stderr.puts "\e[33m#{statement}\e[0m"
    end



    def initialize
      @normalized_controller_name = Hash.new do |hash, controller_name|
        hash[controller_name] = controller_name.underscore.gsub(/_controller$/, "")
      end

      @parsed_uri = Hash.new do |hash, uri|
        hash[uri] = Addressable::URI.parse(uri).path
      end
    end

  private
    attr_reader :normalized_controller_name,
                :parsed_uri

  end
end
