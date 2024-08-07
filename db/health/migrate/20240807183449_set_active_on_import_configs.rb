class SetActiveOnImportConfigs < ActiveRecord::Migration[7.0]
  def change
    Health::ImportConfig.all.each do |config|
      config.update(active: true)
    end
  end
end
