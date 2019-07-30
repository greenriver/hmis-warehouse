class CreateEnrollments < ActiveRecord::Migration
  def change
    create_table :enrollments do |t|
      t.references :user
      t.string :content
      t.string :original_filename

      t.integer :new_patients
      t.integer :returning_patients
      t.integer :disenrolled_patients

      t.timestamps
    end
  end
end
