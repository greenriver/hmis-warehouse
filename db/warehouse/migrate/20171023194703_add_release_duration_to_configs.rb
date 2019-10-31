class AddReleaseDurationToConfigs < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :release_duration, :string, default: 'Indefinite'
  end
end
