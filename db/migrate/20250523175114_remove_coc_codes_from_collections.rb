class RemoveCoCCodesFromCollections < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :collections, :coc_codes, :jsonb }
  end
end
