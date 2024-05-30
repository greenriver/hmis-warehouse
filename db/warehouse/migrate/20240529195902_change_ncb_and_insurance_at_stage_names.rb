class ChangeNcbAndInsuranceAtStageNames < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :hmis_dqt_enrollments do |t|
        t.rename :ncb_from_any_source_at_entry, :ncb_from_any_source_at_entry_remove
        t.rename :ncb_from_any_source_at_annual, :ncb_from_any_source_at_annual_remove
        t.rename :ncb_from_any_source_at_exit, :ncb_from_any_source_at_exit_remove

        t.rename :insurance_from_any_source_at_entry, :insurance_from_any_source_at_entry_remove
        t.rename :insurance_from_any_source_at_annual, :insurance_from_any_source_at_annual_remove
        t.rename :insurance_from_any_source_at_exit, :insurance_from_any_source_at_exit_remove
      end
    end
  end
end
