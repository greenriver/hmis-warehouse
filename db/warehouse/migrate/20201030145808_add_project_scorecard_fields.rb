class AddProjectScorecardFields < ActiveRecord::Migration[5.2]
  def change
    change_table :project_scorecard_reports do |t|
      # header
      t.string :recipient
      t.string :subrecipient
      t.date :start_date
      t.date :end_date
      t.string :funding_year
      t.string :grant_term

      # performance
      t.integer :utilization_jan
      t.integer :utilization_apr
      t.integer :utilization_jul
      t.integer :utilization_oct
      t.integer :utilization_proposed

      t.integer :chronic_households_served
      t.integer :total_households_served

      t.integer :total_persons_served
      t.integer :total_persons_with_positive_exit
      t.integer :total_persons_exited
      t.integer :excluded_exits

      t.integer :average_los_leavers

      t.integer :percent_increased_employment_income_at_exit
      t.integer :percent_increased_other_cash_income_at_exit

      t.integer :percent_returns_to_homelessness

      # data quality
      t.integer :percent_pii_errors
      t.integer :percent_ude_errors
      t.integer :percent_income_and_housing_errors

      # CE
      t.integer :days_to_lease_up
      t.integer :number_referrals
      t.integer :accepted_referrals

      # grant management and financials
      t.integer :funds_expended
      t.integer :amount_awarded
      t.integer :months_since_start
      t.boolean :pit_participation
      t.integer :coc_meetings
      t.integer :coc_meetings_attended

      # review only

      # agency response
      t.string :improvement_plan
      t.string :financial_plan
    end
  end
end
