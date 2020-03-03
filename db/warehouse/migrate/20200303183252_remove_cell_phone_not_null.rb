class RemoveCellPhoneNotNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :youth_intakes, :owns_cell_phone, true
  end
end
