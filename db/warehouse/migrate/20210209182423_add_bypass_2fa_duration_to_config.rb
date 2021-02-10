class AddBypass2faDurationToConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :bypass_2fa_duration, :integer, default: 0, null: false
  end
end
