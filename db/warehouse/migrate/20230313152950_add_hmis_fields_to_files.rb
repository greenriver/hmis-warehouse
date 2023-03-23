class AddHmisFieldsToFiles < ActiveRecord::Migration[6.1]
  def change
    add_reference :files, :enrollment, null: true, index: true
    add_column :files, :confidential, :boolean, null: true
  end
end
