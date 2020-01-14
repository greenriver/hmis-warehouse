class AddLmsUserIdToTalentlmsLogins < ActiveRecord::Migration[5.2]
  def change
    add_column :talentlms_logins, :lms_user_id, :integer
  end
end
