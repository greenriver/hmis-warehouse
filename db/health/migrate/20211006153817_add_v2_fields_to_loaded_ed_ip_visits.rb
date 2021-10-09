class AddV2FieldsToLoadedEdIpVisits < ActiveRecord::Migration[5.2]
  def change
    change_table :loaded_ed_ip_visits do |t|
      t.string :member_record_number
      t.string :patient_identifier
      t.string :patient_url
      t.string :admitted_inpatient
    end
  end
end
