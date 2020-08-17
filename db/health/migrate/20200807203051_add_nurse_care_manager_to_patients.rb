class AddNurseCareManagerToPatients < ActiveRecord::Migration[5.2]
  def change
    add_reference :patients, :nurse_care_manager
  end
end
