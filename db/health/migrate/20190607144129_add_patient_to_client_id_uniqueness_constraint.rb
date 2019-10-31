class AddPatientToClientIdUniquenessConstraint < ActiveRecord::Migration[4.2]
  def up
    execute "CREATE UNIQUE INDEX patients_client_id_constraint ON patients (client_id) WHERE deleted_at IS NULL"
  end

  def down
    execute "DROP INDEX patients_client_id_constraint"
  end
end
