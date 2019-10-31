class AddUniqueNamesTable < ActiveRecord::Migration[4.2]
  def change
    create_table :unique_names do |t|
      t.string :name
      t.string :double_metaphone
    end
  end
end
