class IndexDisabilityType < ActiveRecord::Migration
  def change
    add_index :Disabilities, [:DisabilityType, :DisabilityResponse, :InformationDate, :PersonalID, :EnrollmentID, :DateDeleted], name: :disabilities_disability_type_response_idx
  end
end
