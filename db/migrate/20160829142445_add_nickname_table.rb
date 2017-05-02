class AddNicknameTable < ActiveRecord::Migration
  def change
    create_table :nicknames do |t|
      t.string :name
      t.integer :nickname_id
    end
  end
end
