class AddTimeBeforeEntry < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_dqt_enrollments, :days_before_entry, :integer
  end
end
