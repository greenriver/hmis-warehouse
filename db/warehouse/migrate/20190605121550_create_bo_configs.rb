class CreateBoConfigs < ActiveRecord::Migration[4.2]
  def change
    create_table :bo_configs do |t|
      t.references :data_source
      t.string :user
      t.string :encrypted_pass
      t.string :encrypted_pass_iv
      t.string :url
      t.string :server
      t.string :client_lookup_cuid
      t.string :touch_point_lookup_cuid
    end
  end
end
