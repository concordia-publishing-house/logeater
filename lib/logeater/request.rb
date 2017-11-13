require "active_record"
require "activerecord-import"

module Logeater
  class Request < ActiveRecord::Base
    self.table_name = "requests"

    def self.import(values)
      # values have to be unique by uuid so we pull already saved ones out before trying to insert
      existing_uuids = where(uuid: values.map(&:uuid)).pluck(:uuid)
      values = values.uniq(&:uuid).reject { |request| existing_uuids.member?(request.uuid) }

      super values
    end

  end
end
