class IndexPatientsByMedicaidId < ActiveRecord::Migration
  def change
    add_index :patients, :medicaid_id
  end
end
