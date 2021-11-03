###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importing
  class RunHealthImportJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    PILOT_IMPORT = 'pilot'.freeze

    def perform
      change_counts = Health::Tasks::ImportEpic.new.run!
      change_counts[PILOT_IMPORT] ||= {}
      change_counts[PILOT_IMPORT].merge!(Health::Tasks::PatientClientMatcher.new.run!)
      Health::EpicTeamMember.process!
      Health::EpicQualifyingActivity.update_qualifying_activities!
      Health::QualifyingActivity.transaction do
        Health::QualifyingActivity.where(source_type: GrdaWarehouse::HmisForm.name).unsubmitted.delete_all
        GrdaWarehouse::HmisForm.has_qualifying_activities.each(&:create_qualifying_activity!)
      end
      Health::Patient.update_demographic_from_sources

      return unless change_counts.values.reduce([]) { |arr, hash| arr << hash.values }.flatten.sum.positive?

      # consent changes are only computed for pilot patients, so this produces confusing messages
      # if the data in the import from Epic is corrupted.
      # User.can_administer_health.each do |user|
      #   HealthConsentChangeMailer.consent_changed(
      #     new_patients: change_counts[:new_patients],
      #     consented: change_counts[:consented],
      #     revoked_consent: change_counts[:revoked_consent],
      #     unmatched: change_counts[:unmatched],
      #     user: user,
      #   ).deliver_later
      # end
      Health::Tasks::NotifyCareCoordinatorsOfPatientEligibilityProblems.new.notify!
    end
  end
end
