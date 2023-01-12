class AddClientNamesToHmisDqEnrollmnents < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_dqt_enrollments, :first_name, :string
    add_column :hmis_dqt_enrollments, :last_name, :string
    add_column :hmis_dqt_current_living_situations, :first_name, :string
    add_column :hmis_dqt_current_living_situations, :last_name, :string
  end
end
