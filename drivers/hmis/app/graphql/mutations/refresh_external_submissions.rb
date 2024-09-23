#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class RefreshExternalSubmissions < CleanBaseMutation
    field :success, Boolean, null: false

    def resolve
      handlers = ['HmisExternalApis::ConsumeExternalFormSubmissionsJob']
      return { success: true } if Delayed::Job.queued?(handlers) || Delayed::Job.running?(handlers)

      queue = ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
      HmisExternalApis::ConsumeExternalFormSubmissionsJob.delay(priority: 0, queue: queue)

      { success: true }
    end
  end
end
