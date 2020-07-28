class EncryptPIIFields < ActiveRecord::Migration[5.2]
  def change
    [
      :encrypted_first_name,
      :encrypted_first_name_iv,
      :encrypted_last_name,
      :encrypted_last_name_iv,
      :encrypted_ssn,
      :encrypted_ssn_iv,
    ].each do |column_name|
      add_column :warehouse_data_quality_report_enrollments, column_name, :string
    end
  end
end
