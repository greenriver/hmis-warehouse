class AddCoCCodesToUser < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :coc_codes, array: true, default: []
    end
  end
end
