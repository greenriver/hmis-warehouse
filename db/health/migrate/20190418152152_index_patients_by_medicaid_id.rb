class IndexPatientsByMedicaidId < ActiveRecord::Migration[4.2]
  def change
    add_index :patients, :medicaid_id
  end
end
