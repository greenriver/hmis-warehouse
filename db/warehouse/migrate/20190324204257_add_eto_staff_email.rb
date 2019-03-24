class AddEtoStaffEmail < ActiveRecord::Migration
  def change
    add_column :hmis_forms, :staff_email, :string
  end
end
