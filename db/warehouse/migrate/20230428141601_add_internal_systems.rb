class AddInternalSystems < ActiveRecord::Migration[6.1]
  def change
    create_table :internal_systems do |t|
      t.string :name, null: false
      t.boolean :active, default: true, null: false
      t.string :auth_type, default: HmisExternalApis::InternalSystem::API_KEY, null: false
    end

    add_reference :inbound_api_configurations, :internal_system, foreign_key: true, index: true

    add_index :inbound_api_configurations, [:internal_system_id, :external_system_name, :version], unique: true, name: 'idx_inbound_api_configurations_uniq'

    add_index :internal_systems, :name, unique: true
  end
end
