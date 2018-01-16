require "test_helper"

class ParserTest < ActiveSupport::TestCase
  attr_reader :line



  context "given a line that doesn't start with the generic log prefix, it" do
    setup do
      @line = "\n"
    end

    should "raise UnmatchedLine" do
      assert_raises Logeater::Parser::UnmatchedLine do
        parse!
      end
    end
  end



  context "given any generic log line, it" do
    setup do
      @line = "I, [2015-01-10T15:18:05.850839 #18070]  INFO -- : the message\n"
    end

    should "identify the line as :generic" do
      assert_parses type: :generic
    end

    should "identify the log level" do
      assert_parses log_level: "INFO"
    end

    should "identify the time, including milliseconds" do
      assert_parses timestamp: "2015-01-10T15:18:05.850839"
    end

    should "identify the remainder of the log message" do
      assert_parses message: "the message"
    end
  end



  context "given a log line for a Rails request, it" do
    setup do
      @line = "I, [2015-01-10T15:18:05.850839 #18070]  INFO -- : [livingsaviorco] [2d89d962-57c4-47c9-a9e9-6a16a5f22a12] [gzip] Compress reponse by 42.2 KB (83.3%)  (1.4ms)"
    end

    should "identify the line as :generic" do
      assert_parses type: :request_line
    end

    should "identify the subdomain" do
      assert_parses subdomain: "livingsaviorco"
    end

    should "identify the request's ID" do
      assert_parses uuid: "2d89d962-57c4-47c9-a9e9-6a16a5f22a12"
    end

    should "identify the remainder of the log message" do
      assert_parses message: "[gzip] Compress reponse by 42.2 KB (83.3%)  (1.4ms)"
    end
  end



  context "given a log line for a Rails request" do
    context "that indicates the current user (who was logged in with the tester bar), it" do
      setup do
        @line = "I, [2015-01-10T15:18:05.850839 #18070]  INFO -- : [livingsaviorco] [2d89d962-57c4-47c9-a9e9-6a16a5f22a12] [user.902544074:cph] [gzip] Compress reponse by 42.2 KB (83.3%)  (1.4ms)"
      end

      should "identify the user's id" do
        assert_parses user_id: 902544074
      end

      should "notice that the user was logged-in with the tester bar" do
        assert_parses tester_bar: true
      end

      should "identify the remainder of the log message" do
        assert_parses message: "[gzip] Compress reponse by 42.2 KB (83.3%)  (1.4ms)"
      end
    end

    context "that indicates the current user (who was not logged in with the tester bar), it" do
      setup do
        @line = "I, [2015-01-10T15:18:05.850839 #18070]  INFO -- : [livingsaviorco] [2d89d962-57c4-47c9-a9e9-6a16a5f22a12] [user.902544074] [gzip] Compress reponse by 42.2 KB (83.3%)  (1.4ms)"
      end

      should "identify the user's id" do
        assert_parses user_id: 902544074
      end

      should "notice that the user was not logged-in with the tester bar" do
        assert_parses tester_bar: false
      end

      should "identify the remainder of the log message" do
        assert_parses message: "[gzip] Compress reponse by 42.2 KB (83.3%)  (1.4ms)"
      end
    end

    context "that indicates the current user via email, it" do
      setup do
        @line = "I, [2015-01-10T15:18:05.850839 #18070]  INFO -- : [livingsaviorco] [2d89d962-57c4-47c9-a9e9-6a16a5f22a12] [example@user.com] [gzip] Compress reponse by 42.2 KB (83.3%)  (1.4ms)"
      end

      should "identify the user's email" do
        assert_parses user_id: "example@user.com"
      end

      should "identify the remainder of the log message" do
        assert_parses message: "[gzip] Compress reponse by 42.2 KB (83.3%)  (1.4ms)"
      end
    end

    context "that indicates that the user is logged out, it" do
      setup do
        @line = "I, [2015-01-10T15:18:05.850839 #18070]  INFO -- : [livingsaviorco] [2d89d962-57c4-47c9-a9e9-6a16a5f22a12] [guest] [gzip] Compress reponse by 42.2 KB (83.3%)  (1.4ms)"
      end

      should "identify the user as a guest" do
        assert_parses user_id: nil
      end

      should "identify the remainder of the log message" do
        assert_parses message: "[gzip] Compress reponse by 42.2 KB (83.3%)  (1.4ms)"
      end
    end
  end



  context "given the \"Started\" line, it" do
    setup do
      @line = "I, [2015-01-10T15:18:12.064392 #2354]  INFO -- : [livingsaviorco] [0fc5154a-c288-4bad-9c7a-de3d7e7d2496] Started GET \"/people/1035826228?refresh_page=true\" for 71.218.222.249 at 2015-01-10 15:18:12 +0000"
    end

    should "identify the line as :request_started" do
      assert_parses type: :request_started
    end

    should "identify the HTTP method" do
      assert_parses http_method: "GET"
    end

    should "identify the path (without params)" do
      assert_parses path: "/people/1035826228"
    end

    should "identify the remote client's IP address" do
      assert_parses remote_ip: "71.218.222.249"
    end
  end



  context "given the \"Processing by\" line, it" do
    setup do
      @line = "I, [2015-01-10T15:18:12.067034 #2354]  INFO -- : [livingsaviorco] [0fc5154a-c288-4bad-9c7a-de3d7e7d2496] Processing by Api::V1::PeopleController#show as JS"
    end

    should "identify the line as :request_controller" do
      assert_parses type: :request_controller
    end

    should "identify the controller and action" do
      assert_parses controller: "api/v1/people", action: "show"
    end

    should "identify the format requested" do
      assert_parses format: "JS"
    end
  end



  context "given the \"Parameters\" line, it" do
    setup do
      @line = "I, [2015-01-10T15:18:12.067134 #2354]  INFO -- : [livingsaviorco] [0fc5154a-c288-4bad-9c7a-de3d7e7d2496]   Parameters: {\"refresh_page\"=>\"true\", \"id\"=>\"1035826228\"}"
    end

    should "identify the line as :request_params" do
      assert_parses type: :request_params
    end

    should "identify the params" do
      assert_parses params: {"refresh_page" => "true", "id" => "1035826228"}
    end
  end

  context "when the \"Parameters\" line contains invalid syntax, it" do
    setup do
      @line = "I, [2015-01-10T15:18:12.067134 #2354]  INFO -- : [livingsaviorco] [0fc5154a-c288-4bad-9c7a-de3d7e7d2496]   Parameters: {\"refresh_page\"=>}"
    end

    should "return the params unparsed" do
      assert_parses params: "{\"refresh_page\"=>}"
    end
  end



  context "given the \"Completed\" line, it" do
    setup do
      @line = "I, [2015-01-10T15:18:12.262903 #2354]  INFO -- : [livingsaviorco] [0fc5154a-c288-4bad-9c7a-de3d7e7d2496] Completed 401 Unauthorized in 2ms"
    end

    should "identify the line as :request_completed" do
      assert_parses type: :request_completed
    end

    should "identify the HTTP response" do
      assert_parses http_status: 401, http_response: "Unauthorized"
    end

    should "identify the duration of the request" do
      assert_parses duration: 2
    end
  end

  context "when the \"Completed\" line doesn't have a textual description of the status, it" do
    setup do
      @line = "I, [2015-01-10T15:18:12.262903 #2354]  INFO -- : [livingsaviorco] [0fc5154a-c288-4bad-9c7a-de3d7e7d2496] Completed 307 in 0.8ms"
    end

    should "be cool with that" do
      assert_parses http_status: 307, http_response: nil
    end
  end

  context "when the \"Completed\" line contains a breakdown of times, it" do
    setup do
      @line = "I, [2015-01-10T15:18:12.262903 #2354]  INFO -- : [livingsaviorco] [0fc5154a-c288-4bad-9c7a-de3d7e7d2496] Completed 200 OK in 196ms (Views: 0.1ms | ActiveRecord: 50.0ms)"
    end

    should "identify the duration of the request" do
      assert_parses duration: 196
    end
  end



private

  def assert_parses(expectations)
    results = parse!

    expectations.each do |key, value|
      assert_equal value, results[key]
    end
  end

  def parse!
    parser.parse!(line)
  end

  def parser
    Logeater::Parser.new
  end

end
