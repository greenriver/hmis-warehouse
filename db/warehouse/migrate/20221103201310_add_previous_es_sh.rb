class AddPreviousEsSh < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_dqt_enrollments, :previous_street_es_sh, :integer
    add_column :hmis_dqt_enrollments, :entry_date_entered_at, :datetime
    add_column :hmis_dqt_enrollments, :exit_date_entered_at, :datetime
    add_column :hmis_dqt_enrollments, :days_to_enter_entry_date, :integer
    add_column :hmis_dqt_enrollments, :days_to_enter_exit_date, :integer
  end
end
