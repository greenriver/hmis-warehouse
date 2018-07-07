module Importing
  class RunHealthImportJob < ActiveJob::Base
    queue_as :low_priority

    def perform
      change_counts = Health::Tasks::ImportEpic.new.run!
      change_counts.merge!(Health::Tasks::PatientClientMatcher.new.run!)
      Health::EpicTeamMember.process!

      if change_counts.values.sum > 0
        User.can_administer_health.each do |user|
          HealthConsentChangeMailer.consent_changed(
            new_patients: change_counts[:new_patients],
            consented: change_counts[:consented],
            revoked_consent: change_counts[:revoked_consent],
            unmatched: change_counts[:unmatched],
            user: user
          ).deliver_later
        end
      end
    end

  end
end