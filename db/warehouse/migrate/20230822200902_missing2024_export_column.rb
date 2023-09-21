class Missing2024ExportColumn < ActiveRecord::Migration[6.1]
  def change
    add_column :Export, :ImplementationID, :string
    add_column :IncomeBenefits, :NoVHAReason, :string
    safety_assured { remove_column :IncomeBenefits, :NoVHAServices }
  end
end
