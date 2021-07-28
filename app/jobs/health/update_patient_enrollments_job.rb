###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class UpdatePatientEnrollmentsJob < BaseJob
    queue_as :long_running

    def perform(user)
      return unless GrdaWarehouse::Config.get(:healthcare_available)

      api = Health::Soap::MassHealth.new(test: !Rails.env.production?)
      setup_notifier('Update Patient Enrollments')
      file_list = api.file_list
      enrollment_payloads = file_list.payloads(Health::Soap::MassHealth::ENROLLMENT_RESPONSE_PAYLOAD_TYPE)
      if enrollment_payloads.present?
        enrollment_payloads.each do |payload|
          response = payload.response
          if response.success?
            file = Health::Enrollment.create(
              user_id: user.id,
              content: response.response,
              status: 'processing',
            )
            Health::ProcessEnrollmentChangesJob.perform_later(file.id)
          else
            @notifier.ping('API Error: ' + response.error_message.to_s) if @send_notifications # rubocop:disable Style/IfInsideElse
          end
        end
      else
        @notifier.ping('No 834s found.') if @send_notifications # rubocop:disable Style/IfInsideElse
      end
    end
  end
end
