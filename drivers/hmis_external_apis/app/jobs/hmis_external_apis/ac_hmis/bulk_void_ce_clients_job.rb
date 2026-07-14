###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisExternalApis::AcHmis::BulkVoidCeClientsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  def perform(...)
    HmisExternalApis::AcHmis::BulkVoider.new.perform(...)
  end
end
