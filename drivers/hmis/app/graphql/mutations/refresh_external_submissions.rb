###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class RefreshExternalSubmissions < CleanBaseMutation
    field :success, Boolean, null: false

    def resolve
      # Global check: this re-processes the submission queue across all projects, so there is no
      # single project to authorize against.
      access_denied! unless policy_for(Hmis::Hud::Project, policy_type: :hmis_project).can_manage_external_form_submissions?

      handlers = ['HmisExternalApis::ConsumeExternalFormSubmissionsJob']
      return { success: true } if Delayed::Job.queued?(handlers) || Delayed::Job.running?(handlers)

      queue = ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
      HmisExternalApis::ConsumeExternalFormSubmissionsJob.set(priority: BaseJob::UI_IMMEDIATE_PRIORITY_NEG5, queue: queue).perform_later

      { success: true }
    end
  end
end
