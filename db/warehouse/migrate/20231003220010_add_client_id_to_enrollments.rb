class AddClientIdToEnrollments < ActiveRecord::Migration[6.1]
  def change
    add_column :ansd_enrollments, :destination_client_id, :integer
  end
end
