class AddSpmDependentFieldsToSpmEnrollment < ActiveRecord::Migration[6.1]
  def change
    table = :hud_report_spm_enrollments
    add_column table_name, :veteran, :boolean
    add_column table_name, :veteran, :boolean
    add_column table_name, :dob, :date
    add_column table_name, :source_client_personal_ids, :string
    add_column table_name, :head_of_household, :boolean
  end
end
