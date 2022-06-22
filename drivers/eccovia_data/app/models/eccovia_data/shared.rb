###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module EccoviaData::Shared
  extend ActiveSupport::Concern

  included do
    def self.default_lookback
      3.years.ago
    end

    def self.users(ids, credentials:)
      query = "crql?q=SELECT UserID, CellPhone, OfficePhone, Email FROM osUsers where UserID in (#{quote(ids)})"
      credentials.get_all(query)
    end

    def self.quote(ids)
      ids.map { |id| connection.quote(id) }.join(', ')
    end

    def self.max_fetch_time
      maximum(:last_fetched_at)
    end
  end
end
