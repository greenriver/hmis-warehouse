class AddNumErrorsToEligibilityResponses < ActiveRecord::Migration[5.2]
  def change
    add_column :eligibility_responses, :num_errors, :integer
  end
end
