class AddCoCConfigOptions < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :default_coc_zipcodes, :string
    
  end
end
