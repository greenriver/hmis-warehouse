class AddEngagementColumnsToEnrollments < ActiveRecord::Migration[5.2]
  def change
    add_column :claims_reporting_member_enrollment_rosters, :engagement_date, :date, index: true
    add_column :claims_reporting_member_enrollment_rosters, :engaged_days, :integer
    add_column :claims_reporting_member_enrollment_rosters, :enrollment_end_at_engagement_calculation, :date
  end
end
