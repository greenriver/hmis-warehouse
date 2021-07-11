class AddYouthHhpConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :enable_youth_hrp, :boolean, default: true, null: false
  end
end
