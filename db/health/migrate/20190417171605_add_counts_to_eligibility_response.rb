class AddCountsToEligibilityResponse < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :eligibility_responses, :num_eligible, :integer
    add_column :eligibility_responses, :num_ineligible, :integer
  end
end
