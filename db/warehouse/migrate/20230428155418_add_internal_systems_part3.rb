class AddInternalSystemsPart3 < ActiveRecord::Migration[6.1]
  def up
    HmisExternalApis::InboundApiConfiguration.find_each do |conf|
      internal_system = HmisExternalApis::InternalSystem.where(name: conf.internal_system_name).first_or_initialize
      if internal_system.new_record?
        internal_system.active = false
      end
      conf.internal_system = internal_system
      conf.save!
    end

    remove_column :inbound_api_configurations, :internal_system_name
  end

  def down
      add_column :inbound_api_configurations, :internal_system_name, :string

      # The find_each and/or update in ruby seems to be in a different
      # connection/transaction. Happy to refactor if somebody can explain why.
      execute(<<~SQL)
        UPDATE inbound_api_configurations
        SET internal_system_name = name
        FROM
          internal_systems
        WHERE
          internal_systems.id = internal_system_id
      SQL
  end
end
