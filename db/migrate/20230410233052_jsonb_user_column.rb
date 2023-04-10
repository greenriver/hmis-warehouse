class JsonbUserColumn < ActiveRecord::Migration[6.1]
  def up
    change_column :users, :deprecated_provider_raw_info, :jsonb
  end

  def down
    change_column :users, :deprecated_provider_raw_info, :json
  end
end
