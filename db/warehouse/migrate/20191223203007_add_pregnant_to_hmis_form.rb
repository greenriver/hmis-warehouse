class AddPregnantToHmisForm < ActiveRecord::Migration
  def change
    add_column :hmis_forms, :vispdat_pregnant, :string
    add_column :hmis_forms, :vispdat_pregnant_updated_at, :date
  end
end
