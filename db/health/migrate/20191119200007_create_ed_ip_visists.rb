class CreateEdIpVisists < ActiveRecord::Migration
  def change
    create_table :ed_ip_visit_files do |t|
      t.string :type
      t.string :file
      t.string :content
      t.belongs_to :user, index: true
      t.timestamps null: false, index: true
      t.datetime :deleted_at, index: true
    end
    create_table :ed_ip_visits do |t|
      t.references :ed_ip_visit_file, null: false, index: true
      t.string :medicaid_id, index: true
      t.string :last_name
      t.string :first_name
      t.string :gender
      t.date :dob
      t.date :admit_date
      t.date :discharge_date
      t.string :discharge_disposition
      t.string :encounter_major_class
      t.string :visit_type
      t.string :encounter_facility
      t.string :chief_complaint
      t.string :diagnosis
      t.string :attending_physician
      t.timestamps null: false, index: true
      t.datetime :deleted_at, index: true
    end
  end
end
