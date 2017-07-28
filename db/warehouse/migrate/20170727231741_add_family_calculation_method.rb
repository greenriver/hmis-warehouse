class AddFamilyCalculationMethod < ActiveRecord::Migration
  def change
    add_column :configs, :family_calculation_method, :string, default: :adult_child
    remove_column :configs, :site_coc_codes, :json
    add_column :configs, :site_coc_codes, :string
  end
end
