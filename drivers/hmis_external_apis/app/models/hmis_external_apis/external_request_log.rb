###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class ExternalRequestLog < GrdaWarehouseBase
    has_one :external_id
    belongs_to :initiator, polymorphic: true

    scope :incoming, -> do
      where(initiator_type: 'HmisExternalApis::InternalSystem')
    end

    scope :outgoing, -> do
      where(initiator_type: 'GrdaWarehouse::RemoteCredential')
    end

    scope :failed, -> do
      where(arel_table[:http_status].eq(nil).or(arel_table[:http_status].gt(300)))
    end

    scope :url_like, ->(str) { where('lower(url) LIKE ?', "%#{str.downcase}%") }
    scope :response_like, ->(str) { where('response LIKE ?', "%#{str}%") }
    scope :request_like, ->(str) { where('request LIKE ?', "%#{str}%") }
  end
end
