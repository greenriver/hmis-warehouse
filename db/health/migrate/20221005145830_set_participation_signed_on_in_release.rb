class SetParticipationSignedOnInRelease < ActiveRecord::Migration[6.1]
  def up
    Health::Patient.participating.find_each do |patient|
      release = patient.recent_release_form
      next unless release.present?

      participation_date = patient.recent_participation_form&.signature_on
      if participation_date.blank?
        # If we don't have an earlier participation signature, use the one on the release
        participation_date = release.signature_on
      end
      release.update(participation_signature_on: participation_date)
    end
  end
end
