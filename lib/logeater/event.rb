require "active_record"

module Logeater
  class Event < ActiveRecord::Base
    self.table_name = "events"

    def self.since(timestamp)
      where(arel_table[:received_at].gteq(timestamp))
    end
  end
end
