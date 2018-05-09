class MoveConsentTypeToFile < ActiveRecord::Migration
  def up
    GrdaWarehouse::Hud::Client.with_confirmed_consent.each do |client|
      most_recent_consent_form = client.client_files.consent_forms.confirmed.
        order(consent_form_confirmed: :desc, consent_form_signed_on: :desc).limit(1).first
      puts "Setting consent type for #{client.id} to #{client.housing_release_status} on file: #{most_recent_consent_form.id}"
      most_recent_consent_form.update_column(:consent_type, client.housing_release_status)
    end
  end
end
