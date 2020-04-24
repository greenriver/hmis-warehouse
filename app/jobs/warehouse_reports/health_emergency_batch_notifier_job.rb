###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class HealthEmergencyBatchNotifierJob < BaseJob
    def perform
      medical_restriction_batch_id = nil
      test_batch_id = nil

      unsent_medical_restrictions = GrdaWarehouse::HealthEmergency::AmaRestriction.active.unsent.count
      medical_restriction_batch_id = GrdaWarehouse::HealthEmergency::AmaRestriction.next_batch_id if unsent_medical_restrictions.positive?

      unsent_test_results = GrdaWarehouse::HealthEmergency::Test.unsent.count
      test_batch_id = GrdaWarehouse::HealthEmergency::Test.next_batch_id if unsent_test_results.positive?

      return unless medical_restriction_batch_id || test_batch_id

      User.receives_medical_restriction_notifications.distinct.pluck(:id).each do |user_id|
        NotifyUser.health_emergency_change(
          user_id, medical_restriction_batch_id:
          medical_restriction_batch_id,
                   unsent_medical_restrictions: unsent_medical_restrictions,
                   test_batch_id: test_batch_id,
                   unsent_test_results: unsent_test_results
        ).deliver_later
      end

      sent_at = Time.current
      GrdaWarehouse::HealthEmergency::AmaRestriction.unsent.update_all(notification_at: sent_at, notification_batch_id: medical_restriction_batch_id)
      GrdaWarehouse::HealthEmergency::Test.unsent.update_all(notification_at: sent_at, notification_batch_id: test_batch_id)
    end

    def max_attempts
      1
    end

    def error(job, exception)
      @report = report_source.find(report_id)
      @report.update(error: "Failed: #{exception.message}")
      super(job, exception)
    end
  end
end
