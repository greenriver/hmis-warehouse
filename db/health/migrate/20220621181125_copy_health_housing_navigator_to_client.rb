class CopyHealthHousingNavigatorToClient < ActiveRecord::Migration[6.1]
  def up
    PaperTrail.enabled = false # Migration fails with can't find 'versions' table w/ papertrail enabled.

    Health::Patient.find_each do |patient|
      next unless patient.client_id.present?

      client = GrdaWarehouse::Hud::Client.find_by(id: patient.client_id)
      next unless client.present?

      client.update!(health_housing_navigator_id: patient.housing_navigator_id)
    end
  end
end
