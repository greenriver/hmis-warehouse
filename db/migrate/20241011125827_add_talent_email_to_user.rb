class AddTalentEmailToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :talent_lms_email, :varchar
  end
end
