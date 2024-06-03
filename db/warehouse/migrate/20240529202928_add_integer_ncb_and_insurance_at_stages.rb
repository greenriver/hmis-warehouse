class AddIntegerNcbAndInsuranceAtStages < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :hmis_dqt_enrollments do |t|
        t.integer :ncb_from_any_source_at_entry, default: nil
        t.integer :ncb_from_any_source_at_annual, default: nil
        t.integer :ncb_from_any_source_at_exit, default: nil

        t.integer :insurance_from_any_source_at_entry, default: nil
        t.integer :insurance_from_any_source_at_annual, default: nil
        t.integer :insurance_from_any_source_at_exit, default: nil
      end
    end
  end
end
