class ReplaceCoverageInquiryFields < ActiveRecord::Migration
  def change
    add_column :patients, :coverage_level, :string
    add_column :patients, :coverage_inquiry_date, :date

    # Coverage information is advisory and will be regenerated with the next 271, so it doesn't need to be preserved
    remove_column :patients, :ineligible
  end
end
