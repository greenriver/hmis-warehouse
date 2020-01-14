class AddPregnantToHmisForm < ActiveRecord::Migration[4.2]
  def change
    add_column :hmis_forms, :vispdat_pregnant, :string, index: true
    add_column :hmis_forms, :vispdat_pregnant_updated_at, :date, index: true
  end
end
