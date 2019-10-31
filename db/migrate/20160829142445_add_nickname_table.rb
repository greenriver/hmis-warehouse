class AddNicknameTable < ActiveRecord::Migration[4.2]
  def change
    create_table :nicknames do |t|
      t.string :name
      t.integer :nickname_id
    end
  end
end
