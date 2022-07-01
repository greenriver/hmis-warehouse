class AddEducationStatusDateToYyaReport < ActiveRecord::Migration[6.1]
  def change
    change_table :ma_yya_report_clients do |t|
      t.date :education_status_date
      t.date :rehoused_on
      end
  end
end
