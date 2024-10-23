class AddRevokedByToFile < ActiveRecord::Migration[7.0]
  def change
    add_column :files, :consent_revoked_by_user_id, :integer, null: true
  end
end
