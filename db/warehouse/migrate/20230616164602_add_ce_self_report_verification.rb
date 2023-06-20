class AddCeSelfReportVerification < ActiveRecord::Migration[6.1]
  def change
    add_column :available_file_tags, :ce_self_report_certification, :boolean, default: false, null: false
  end
end
