class SetActiveOnImportConfigs < ActiveRecord::Migration[7.0]
  def up
    Health::ImportConfig.update_all(active: true)
  end
end
