require "logeater/request"
require "zlib"
require "ruby-progressbar"
require "oj"

module Logeater
  class Reader
    attr_reader :app, :file, :batch_size

    def initialize(app, file, options={})
      @app = app
      @file = file
      @file.show_progress = options.fetch :progress, false
      @parser = Logeater::Parser.new
      @batch_size = options.fetch :batch_size, 500
      @verbose = options.fetch :verbose, false
      @count = 0
      @requests = {}
      @completed_requests = []
    end



    def reimport
      remove_existing_entries!
      import
    end

    def import
      @count = 0
      each_request do |attributes|
        completed_requests.push Logeater::Request.new(attributes)
        save! if completed_requests.length >= batch_size
      end
      save!
      @count
    end

    def parse(to: $stdout)
      to << "["
      first = true
      each_request do |attributes|
        if first
          first = false
        else
          to << ",\n"
        end

        to << Oj.dump(attributes, mode: :compat)
      end
    ensure
      to << "]"
    end

    def remove_existing_entries!
      Logeater::Request.where(app: app, logfile: file.filename).delete_all
    end

    def verbose?
      @verbose
    end

    def each_request
      count = 0
      file.each_line do |line|
        process_line! line do |request|
          yield request
          count += 1
        end
      end
      count
    end



  private
    attr_reader :parser, :requests, :completed_requests

    def process_line!(line, &block)
      attributes = parser.parse!(line)

      return if [:generic, :request_line].member? attributes[:type]

      if attributes[:type] == :request_started
        requests[attributes[:uuid]] = attributes
          .slice(:uuid, :subdomain, :http_method, :path, :remote_ip, :user_id, :tester_bar)
          .merge(started_at: attributes[:timestamp], logfile: file.filename, app: app)
        return
      end

      request_attributes = requests[attributes[:uuid]]
      unless request_attributes
        log "Attempting to record #{attributes[:type].inspect}; but there is no request started with UUID #{attributes[:uuid].inspect}" if verbose?
        return
      end

      case attributes[:type]
      when :request_controller
        request_attributes.merge! attributes.slice(:controller, :action, :format)

      when :request_params
        request_attributes.merge! attributes.slice(:params)

      when :request_completed
        request_attributes.merge! attributes
          .slice(:http_status, :duration)
          .merge(completed_at: attributes[:timestamp])

        yield request_attributes
        requests.delete attributes[:uuid]
      end

    rescue Logeater::Parser::UnmatchedLine
      $stderr.puts "\e[90m#{$!.message}\e[0m" if verbose?
    rescue Logeater::Parser::Error
      log $!.message
    end

    def save!
      return if completed_requests.empty?
      Logeater::Request.import(completed_requests)
      @count += completed_requests.length
      completed_requests.clear
    end



    def log(statement)
      $stderr.puts "\e[33m#{statement}\e[0m"
    end

  end
end
