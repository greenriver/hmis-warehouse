class CreateCpMemberFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :cp_member_files do |t|
      t.string :type
      t.string :file
      t.string :content
      t.belongs_to :user

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
