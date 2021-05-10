class AddPreEnrollmentDaysToEnrollments < ActiveRecord::Migration[5.2]
  def change
    add_column :claims_reporting_member_enrollment_rosters, :pre_engagement_days, :integer, default: 0
  end
end
