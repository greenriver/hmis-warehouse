class RelaxHl7ValueSetCodesSchema < ActiveRecord::Migration[5.2]
  def up
    change_column_null :hl7_value_set_codes, :code_system_oid, true
    add_index :hl7_value_set_codes, [:value_set_oid, :code_system, :code], unique: true, name: 'hl_value_set_code_uniq_by_code_system_code'
  end

  def down
    HL7::ValueSetCode.where('code_system_oid IS NULL').update_all("code_system_oid = 'x.' || code_system")
    change_column_null :hl7_value_set_codes, :code_system_oid, false
    remove_index :hl7_value_set_codes, name: 'hl_value_set_code_uniq_by_code_system_code'
  end
end
