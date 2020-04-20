class AddEdiNameToAco < ActiveRecord::Migration[5.2]
  def change
    add_column :accountable_care_organizations, :edi_name, :string
  end
end
