class AddReleaseDurationToConfigs < ActiveRecord::Migration
  def change
    add_column :configs, :release_duration, :string, default: 'Indefinite'
  end
end
