class AddCongregateHousingToClientDetails < ActiveRecord::Migration

  def up
    config = GrdaWarehouse::Config.first
    if config.present? && config.client_details
      details = config.client_details
      details = details + ['congregate_housing', 'sober_housing']
      config.update(client_details: details)
    end
  end

  def down
    config = GrdaWarehouse::Config.first
    if config
      details = config.client_details
      details = details - ['congregate_housing', 'sober_housing']
      config.update(client_details: details)
    end
  end

end
