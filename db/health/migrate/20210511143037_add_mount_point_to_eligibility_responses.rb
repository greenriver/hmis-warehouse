class AddMountPointToEligibilityResponses < ActiveRecord::Migration[5.2]
  def change
    add_column :eligibility_responses, :file, :string
  end
end
