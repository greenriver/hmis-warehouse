class AddMedicaidIdToPatients < ActiveRecord::Migration
  def change
    add_column :patients, :medicaid_id, :string
  end
end
