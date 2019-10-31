class AddCoCCodesToUser < ActiveRecord::Migration[4.2]
  def change
    change_table :users do |t|
      t.string :coc_codes, array: true, default: []
    end
  end
end
