class UpdatesExitEnrollmentIndexes < ActiveRecord::Migration[6.1]
  include ArelHelper
  def change
    remove_index :Exit, [:data_source_id, :PersonalID]
    remove_index :Exit, :data_source_id
    remove_index :Exit, :PersonalID
    remove_index :Exit, :EnrollmentID

    add_index :Exit, [:EnrollmentID, :PersonalID, :data_source_id, :ExitDate], name: 'exit_en_id_p_id_ds_id_ex_d_undeleted', where: ex_t[:DateDeleted].eq(nil).to_sql
    add_index :Exit, [:EnrollmentID, :PersonalID, :data_source_id, :ExitDate], name: 'exit_en_id_p_id_ds_id_ex_d'
    add_index :Exit, [:PersonalID, :data_source_id], name: 'exit_p_id_ds_id', where: ex_t[:DateDeleted].eq(nil).to_sql
    add_index :Enrollment, [:ProjectID, :data_source_id], where: e_t[:DateDeleted].eq(nil).to_sql
  end
end
