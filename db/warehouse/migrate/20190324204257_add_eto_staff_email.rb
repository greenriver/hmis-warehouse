class AddEtoStaffEmail < ActiveRecord::Migration[4.2]
  def change
    add_column :hmis_forms, :staff_email, :string
  end
end
