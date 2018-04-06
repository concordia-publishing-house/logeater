require "test_helper"
require "heroku-log-parser"

class LogeaterTest < ActiveSupport::TestCase
  attr_reader :logfile, :events


  context "Given the log of a single request, it" do
    setup do
      @logfile = File.expand_path("../../data/single_request.log", __FILE__)
    end

    should "identify the name of the logfile" do
      assert_equal "single_request.log", logfile_reader.file.filename
    end

    should "create an entry in the database" do
      assert_difference "Logeater::Request.count", +1 do
        logfile_reader.import
      end
    end

    should "set all the attributes" do
      logfile_reader.import
      request = Logeater::Request.first

      params = {"refresh_page" => "true", "id" => "1035826228"}
      assert_equal "test", request.app
      assert_equal "single_request.log", request.logfile
      assert_equal "0fc5154a-c288-4bad-9c7a-de3d7e7d2496", request.uuid
      assert_equal "livingsaviorco", request.subdomain
      assert_equal Time.utc(2015, 1, 10, 15, 18, BigDecimal.new("12.064392")), request.started_at
      assert_equal Time.utc(2015, 1, 10, 15, 18, BigDecimal.new("12.262903")), request.completed_at
      assert_equal 196, request.duration
      assert_equal "GET", request.http_method
      assert_equal "/people/1035826228", request.path
      assert_equal params, request.params
      assert_equal "people", request.controller
      assert_equal "show", request.action
      assert_equal "71.218.222.249", request.remote_ip
      assert_equal "JS", request.format
      assert_equal 200, request.http_status
    end

    should "erase any entries that had already been imported with that app and filename" do
      Logeater::Request.create!(app: app, logfile: "single_request.log", uuid: "1")
      Logeater::Request.create!(app: app, logfile: "single_request.log", uuid: "2")
      Logeater::Request.create!(app: app, logfile: "single_request.log", uuid: "3")

      assert_difference "Logeater::Request.count", -2 do
        logfile_reader.reimport
      end
    end
  end


  context "Given a gzipped logfile, it" do
    setup do
      @logfile = File.expand_path("../../data/single_request.gz", __FILE__)
    end

    should "create an entry in the database" do
      assert_difference "Logeater::Request.count", +1 do
        logfile_reader.import
      end
    end
  end


  context "Given an app and a timestamp, import_since" do
    setup do
      log_sample = File.open(File.expand_path("./test/data/single_heroku_request.log"))
      log_sample.lines do |line|
        Logeater::Event.create HerokuLogParser.parse(line).first.merge(ep_app: app)
      end
      @events = Logeater::Event.all
    end

    should "import events since that given timestamp" do
      assert_difference "Logeater::Request.count", +1 do
        eventfile_reader.import
      end
    end

    should "not reimport events if given twice" do
      assert_difference "Logeater::Request.count", +1 do
        eventfile_reader.import
      end

      assert_no_difference "Logeater::Request.count" do
        eventfile_reader.import
      end
    end
  end

  context "Given a partial request in one import and the rest in a subsiquent import, it" do
    setup do
      @lines = File.open(File.expand_path("./test/data/single_heroku_request.log")).lines.to_a
    end

    should "save the request after having the full request" do
      # The first two lines will not be enough to describe a complete request
      # so Logeater will not be able to create a request from them...
      @lines[0...2].each do |line|
        Logeater::Event.create HerokuLogParser.parse(line).first.merge(ep_app: app)
      end
      @events = Logeater::Event.all
      assert_no_difference "Logeater::Request.count" do
        eventfile_reader.import
      end

      # ...but if we later discover the rest of the lines that describe a complete
      # request, it'd be good if Logeater could then recognize and import it.
      @lines[2..-1].each do |line|
        Logeater::Event.create HerokuLogParser.parse(line).first.merge(ep_app: app)
      end
      @events = Logeater::Event.all
      assert_difference "Logeater::Request.count", +1 do
        eventfile_reader.import
      end
    end
  end


private

  def app
    "test"
  end

  def logfile_reader
    Logeater::Reader.new(app, Logeater::Logfile.new(logfile))
  end

  def eventfile_reader
    Logeater::Reader.new(app, Logeater::Eventfile.new(events))
  end

end
