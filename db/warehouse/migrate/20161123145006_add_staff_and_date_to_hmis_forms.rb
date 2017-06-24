class AddStaffAndDateToHmisForms < ActiveRecord::Migration
  def change
    add_column :hmis_forms, :collected_at, :datetime
    add_column :hmis_forms, :staff, :string
    add_column :hmis_forms, :assessment_type, :string
  end
end
