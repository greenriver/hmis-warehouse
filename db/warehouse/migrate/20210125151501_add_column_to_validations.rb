class AddColumnToValidations < ActiveRecord::Migration[5.2]
  def change
    add_column :hmis_csv_import_validations, :validated_column, :string
  end
end
