class FixDisabledMhxImportConfigs < ActiveRecord::Migration[7.0]
  def up
    Health::ImportConfig.where(kind: 'disabled_medicaid_hmis_exchange').
      update_all(
        kind: 'medicaid_hmis_exchange',
        type: 'Health::ImportConfigSsh',
        active: false,
      )
  end
end
