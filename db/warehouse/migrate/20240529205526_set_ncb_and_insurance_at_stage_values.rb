class SetNcbAndInsuranceAtStageValues < ActiveRecord::Migration[7.0]
  def up
    # The original types of these fields was wrong, just set them all to "collected"
    HmisDataQualityTool::Enrollment.update_all(
      ncb_from_any_source_at_entry: 1,
      ncb_from_any_source_at_annual: 1,
      ncb_from_any_source_at_exit: 1,
      insurance_from_any_source_at_entry: 1,
      insurance_from_any_source_at_annual: 1,
      insurance_from_any_source_at_exit: 1,
    )
  end
end
