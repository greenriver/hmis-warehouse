class CreateEdIpVisits < ActiveRecord::Migration[5.2]
  def change
    create_table :ed_ip_visits do |t|
      t.references :loaded_ed_ip_visit
      t.string :medicaid_id, index: true
      t.date :admit_date
      t.string :encounter_major_class
    end
  end
end
