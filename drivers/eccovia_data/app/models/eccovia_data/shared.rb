###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
      query = "crql?q=SELECT UserID, CellPhone, OfficePhone, Email, UserName FROM osUsers where UserID in (#{quote(ids)})"
      credentials.get_all(query)
    end

    def self.quote(ids)
      ids.map { |id| connection.quote(id) }.join(', ')
    end

    def self.max_fetch_time(data_source_id)
      where(data_source_id: data_source_id).maximum(:last_fetched_at)
    end
  end
end
