class AddCountsToEligibilityResponse < ActiveRecord::Migration
  def change
    add_column :eligibility_responses, :num_eligible, :integer
    add_column :eligibility_responses, :num_ineligible, :integer
  end
end
