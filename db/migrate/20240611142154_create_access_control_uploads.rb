class CreateAccessControlUploads < ActiveRecord::Migration[7.0]
  def change
    create_table :access_control_uploads do |t|
      t.references :user, null: false
      t.string :status
      t.jsonb :metadata
      t.timestamps
    end
  end
end
