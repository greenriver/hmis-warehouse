###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PublicReports::AssetsHelper
  ASSETS = ['public_report.css', 'public_report.js', 'town_map.js', 'who_page.js'].freeze

  def public_report_asset(name)
    raise ArgumentError, "Unknown public report asset: #{name}" unless ASSETS.include?(name)

    File.read(Rails.root.join('drivers/public_reports/lib/public_reports/assets', name)).html_safe
  end

  def public_report_glossary
    @public_report_glossary ||= PublicReports::Glossary.from_translation
  end
end
