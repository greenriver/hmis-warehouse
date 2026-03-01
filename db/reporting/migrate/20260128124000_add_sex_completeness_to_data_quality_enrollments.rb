# frozen_string_literal: true

class AddSexCompletenessToDataQualityEnrollments < ActiveRecord::Migration[6.1]
  def change
    add_column :warehouse_data_quality_report_enrollments, :sex, :integer
    add_column :warehouse_data_quality_report_enrollments, :sex_complete, :boolean, default: false
    add_column :warehouse_data_quality_report_enrollments, :sex_missing, :boolean, default: false
    add_column :warehouse_data_quality_report_enrollments, :sex_refused, :boolean, default: false
    add_column :warehouse_data_quality_report_enrollments, :sex_not_collected, :boolean, default: false
  end
end
