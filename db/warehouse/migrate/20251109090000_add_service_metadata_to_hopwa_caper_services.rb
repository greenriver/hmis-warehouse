# frozen_string_literal: true

class AddServiceMetadataToHopwaCaperServices < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      change_table :hopwa_caper_services, bulk: true do |t|
        t.string :service_source
        t.string :service_category_name
        t.string :service_type_name
      end

      execute <<~SQL.squish
        UPDATE hopwa_caper_services
        SET service_source = 'hud_service'
        WHERE service_source IS NULL
      SQL

      change_column_null :hopwa_caper_services, :service_source, false

      # this index is redundant with the composite index
      remove_index :hopwa_caper_services, name: 'uidx_hopwa_caper_services', if_exists: true

      # service_id might be a custom or a HUD service, adds service_source to the composite key to differentiate them
      remove_index :hopwa_caper_services, name: :index_hopwa_caper_services_on_report_instance_id
      add_index(
        :hopwa_caper_services,
        [:report_instance_id, :service_source, :service_id],
        unique: true,
        name: 'uidx_hopwa_caper_services',
      )
    end
  end
end
