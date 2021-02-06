class CreateEnrollmentReasons < ActiveRecord::Migration[5.2]
  def change
    create_table :enrollment_reasons do |t|
      t.string :file
      t.string :name
      t.string :size
      t.string :content_type
      t.binary :content

      t.timestamps
    end
  end
end
