class UpdateHomelessSummaryBreakdownsForRaceAndEthnicity < ActiveRecord::Migration[7.0]
  def change
    HomelessSummaryReport::Client::HOUSEHOLD_VARIANTS.each do |variant_slug|
      HomelessSummaryReport::Client::DEMOGRAPHIC_VARIANTS.each do |sub_variant_slug|
        col = HomelessSummaryReport::Client.adjust_attribute_name("spm_#{variant_slug}__#{sub_variant_slug}")
        add_column :homeless_summary_report_clients, col, :integer unless column_exists?(:homeless_summary_report_clients, col)
      end
    end
  end
end
