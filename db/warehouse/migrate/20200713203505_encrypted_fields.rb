class EncryptedFields < ActiveRecord::Migration[5.2]
  def change
    [
      :encrypted_FirstName,
      :encrypted_FirstName_iv,
      :encrypted_MiddleName,
      :encrypted_MiddleName_iv,
      :encrypted_LastName,
      :encrypted_LastName_iv,
      :encrypted_SSN,
      :encrypted_SSN_iv,
      :encrypted_NameSuffix,
      :encrypted_NameSuffix_iv,
    ].each do |column_name|
      add_column :Client, column_name, :string
    end
  end
end
