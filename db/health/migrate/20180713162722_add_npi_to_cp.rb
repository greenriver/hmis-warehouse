class AddNpiToCp < ActiveRecord::Migration[4.2]
  def change
    add_column :cps, :npi, :string
    add_column :cps, :ein, :string
  end
end
