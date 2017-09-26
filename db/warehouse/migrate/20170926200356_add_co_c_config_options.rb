class AddCoCConfigOptions < ActiveRecord::Migration
  def change
    add_column :configs, :default_coc_zipcodes, :string
    
  end
end
