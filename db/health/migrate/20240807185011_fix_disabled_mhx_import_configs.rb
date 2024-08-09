class FixDisabledMhxImportConfigs < ActiveRecord::Migration[7.0]
  def change
    Health::ImportConfig.where(kind: 'disabled_medicaid_hmis_exchange').each do |config|
      config.update(
        kind: 'medicaid_hmis_exchange',
        type: 'Health::ImportConfigSsh',
        active: false,
      )
    end
  end
end
