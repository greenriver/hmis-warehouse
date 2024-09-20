#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class RefreshExternalSubmissions < CleanBaseMutation
    field :success, Boolean, null: false

    def resolve
      handlers = ['HmisExternalApis::ConsumeExternalFormSubmissionsJob']
      return if Delayed::Job.queued?(handlers) || Delayed::Job.running?(handlers)

      queue = ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)
      HmisExternalApis::ConsumeExternalFormSubmissionsJob.delay(priority: 12, queue: queue)

      { success: true }
    end
  end
end
