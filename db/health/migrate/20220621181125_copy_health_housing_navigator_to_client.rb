class CopyHealthHousingNavigatorToClient < ActiveRecord::Migration[6.1]
  def up
    PaperTrail.enabled = false # Migration fails with can't find 'versions' table w/ papertrail enabled.

    Health::Patient.find_each do |patient|
      client = GrdaWarehouse::Hud::Client.find(patient.client_id)
      client.update!(health_housing_navigator_id: patient.housing_navigator_id) if client.present?
    end
  end
end
