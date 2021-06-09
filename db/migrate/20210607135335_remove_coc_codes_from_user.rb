class RemoveCoCCodesFromUser < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :coc_codes, array: true, default: []
  end
end
