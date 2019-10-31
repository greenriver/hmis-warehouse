class AddUploadInformationToEligibiltyResponse < ActiveRecord::Migration[4.2][4.2]
  def change
    add_reference :eligibility_responses, :user
    add_column :eligibility_responses, :original_filename, :string
    add_column :eligibility_responses, :deleted_at, :datetime, index: true
  end
end
