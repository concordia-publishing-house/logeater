require "test_helper"

class EventTest < ActiveSupport::TestCase
  attr_reader :event

  context "Given an event formatted using RFC 5424" do
    setup do
      @event = Logeater::Event.new(
        emitted_at: Time.new(2018, 4, 6, 10, 15, 30),
        priority: 190,
        message: "Started GET or something")
    end

    should "generate a parseable logger line" do
      assert_match Logeater::Parser::LINE_MATCHER, event.logger_line
    end
  end

end
