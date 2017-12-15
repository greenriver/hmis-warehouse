class MoveHousingAssistanceNetworkReleaseToConsent < ActiveRecord::Migration
  def up
    clients = GrdaWarehouse::Hud::Client.destination.
      where.not(housing_assistance_network_released_on: nil).
      where(consent_form_signed_on: nil)
    clients.each do |client|
      client.update_column(:consent_form_signed_on, client.housing_assistance_network_released_on)
    end
  end
end
