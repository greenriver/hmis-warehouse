class AddEligibilityNotificationToPatients < ActiveRecord::Migration
  def change
    add_column :patients, :eligibility_notification, :datetime
  end
end
