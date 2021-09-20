class AddMultiGenderToDqEnrollments < ActiveRecord::Migration[5.2]
  def change
    add_column :warehouse_data_quality_report_enrollments, :gender_multi, :jsonb
  end
end
