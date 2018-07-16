class AddNpiToCp < ActiveRecord::Migration
  def change
    add_column :cps, :npi, :string
    add_column :cps, :ein, :string
  end
end
