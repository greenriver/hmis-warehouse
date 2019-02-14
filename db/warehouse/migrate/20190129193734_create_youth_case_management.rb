class CreateYouthCaseManagement < ActiveRecord::Migration
  def change
    create_table :youth_case_managements do |t|
      t.references :client
      t.references :user
      t.date :engaged_on
      t.text :activity
      
      t.timestamps null: false
      t.datetime :deleted_at, index: true
    end
  end
end
