###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Deferred logging for remote connections.
# caller is responsible for calling finalize! to persist the records
module HmisExternalApis
  class OauthDeferredClientLogger < ExternalApiLogger
    attr_accessor :log_records

    def initialize
      self.log_records = []
    end

    def finalize!
      log_records.each(&:save!)
    end

    protected

    def new_log_record(...)
      record = HmisExternalApis::ExternalRequestLog.new(...)
      log_records.push(record)
      record
    end

    def update_log_record(record, attrs)
      record.assign_attributes(attrs)
    end
  end
end
