class Hl7ValueSetCodes < ActiveRecord::Migration[5.2]
  def change
    create_table :hl7_value_set_codes do |t|
      t.string :value_set_name, null: false
      t.string :value_set_oid, null: false
      t.string :value_set_version
      t.string :code_system, null: false
      t.string :code_system_oid, null: false
      t.string :code_system_version
      t.string :code, null: false
      t.string :definition
      t.index [:code, :code_system], name: 'hl_value_set_code'

      # allow only one version to be present at a time for now
      # this might be relaxed in the future
      t.index [:value_set_name, :code_system, :code], unique: true, name: 'hl_value_set_code_uniq_by_name'
      t.index [:value_set_oid, :code_system_oid, :code], unique: true, name: 'hl_value_set_code_uniq_by_oid'
      t.timestamps
    end
  end
end
