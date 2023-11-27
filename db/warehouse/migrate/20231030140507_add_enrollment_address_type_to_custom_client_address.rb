class AddEnrollmentAddressTypeToCustomClientAddress < ActiveRecord::Migration[6.1]
  def change
    add_column :CustomClientAddress, :enrollment_address_type, :string
    # CustomClientAddress is a smaller table (?) so no need for concurrent index creation
    safety_assured do
      add_index(
        :CustomClientAddress,
        [:data_source_id, :EnrollmentID],
        unique: true,
        where: %("CustomClientAddress"."enrollment_address_type" = 'move_in' AND "CustomClientAddress"."DateDeleted" is NULL),
      )
    end
  end
end
