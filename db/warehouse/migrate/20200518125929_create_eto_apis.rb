class CreateEtoApis < ActiveRecord::Migration[5.2]
  def change
    add_column :eto_api_configs, :identifier, :string
    add_column :eto_api_configs, :email, :string
    add_column :eto_api_configs, :encrypted_password, :string
    add_column :eto_api_configs, :encrypted_encrypted_password_iv, :string
    add_column :eto_api_configs, :enterprise, :string
    add_column :eto_api_configs, :hud_touch_point_id, :string
  end
end
