###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Importing
  class RunHealthImportJob < BaseJob
    queue_as :low_priority

    def perform
      change_counts = Health::Tasks::ImportEpic.new.run!
      change_counts.merge!(Health::Tasks::PatientClientMatcher.new.run!)
      Health::EpicTeamMember.process!
      Health::EpicQualifyingActivity.update_qualifying_activities!
      Health::QualifyingActivity.transaction do
        Health::QualifyingActivity.where(source_type: GrdaWarehouse::HmisForm.name).unsubmitted.delete_all
        GrdaWarehouse::HmisForm.has_qualifying_activities.each(&:create_qualifying_activity!)
      end
      Health::Patient.update_demographic_from_sources

      return unless change_counts.values.sum.positive?

      User.can_administer_health.each do |user|
        HealthConsentChangeMailer.consent_changed(
          new_patients: change_counts[:new_patients],
          consented: change_counts[:consented],
          revoked_consent: change_counts[:revoked_consent],
          unmatched: change_counts[:unmatched],
          user: user,
        ).deliver_later
      end
    end
  end
end
