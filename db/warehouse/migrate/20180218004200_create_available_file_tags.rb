class CreateAvailableFileTags < ActiveRecord::Migration
  def change
    create_table :available_file_tags do |t|
      t.string :name
      t.string :group
      t.string :included_info
      t.integer :weight, default: 0
      t.timestamps null: false
    end
  end
end
