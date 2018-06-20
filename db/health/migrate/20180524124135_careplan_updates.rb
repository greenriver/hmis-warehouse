class CareplanUpdates < ActiveRecord::Migration
  def change
    add_column :careplans, :initial_date, :datetime
    add_column :careplans, :review_date, :datetime
    add_column :careplans, :patient_health_problems, :text
    add_column :careplans, :patient_strengths, :text
    add_column :careplans, :patient_goals, :text
    add_column :careplans, :patient_barriers, :text

    add_column :careplans, :status, :string
    add_column :careplans, :responsible_team_member_id, :integer
    add_column :careplans, :provider_id, :integer
    add_column :careplans, :representative_id, :integer
    add_column :careplans, :responsible_team_member_signed_on, :datetime
    add_column :careplans, :representative_signed_on, :datetime
  end
end
