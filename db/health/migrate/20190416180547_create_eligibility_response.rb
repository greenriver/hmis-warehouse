class CreateEligibilityResponse < ActiveRecord::Migration[4.2][4.2]
  def change
    create_table :eligibility_responses do |t|
      t.references :eligibility_inquiry
      t.string :response

      t.timestamps
    end
  end
end
