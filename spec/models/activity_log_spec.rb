###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityLog do
  let(:user) { create(:user) }

  def log(path:, referrer: nil)
    described_class.create!(user: user, path: path, referrer: referrer, controller_name: 'x', action_name: 'show', ip_address: '127.0.0.1')
  end

  describe '.warehouse_reports' do
    it 'matches a path under a known report url' do
      entry = log(path: '/warehouse_reports/chronic/1234')

      expect(described_class.warehouse_reports).to include(entry)
    end

    it "excludes a path that doesn't match any report url" do
      entry = log(path: '/not_a_report/whatever')

      expect(described_class.warehouse_reports).not_to include(entry)
    end

    # Nightly Census's date_range/details sub-routes are also hit by an AJAX widget embedded on
    # the project show page, so ReportDefinition gives it a referrer-aware `reporting_query`
    # override (see app/models/grda_warehouse/warehouse_reports/report_definition.rb). This scope
    # has to honor that override, not just the default path-prefix rule, or callers relying on it
    # (e.g. AccessLogs::WarehouseReports::UsageSummary) inherit the over-count.
    it 'excludes a Nightly Census sub-route referred from a project page rather than the report' do
      entry = log(path: '/censuses/date_range', referrer: 'https://hmis-warehouse.dev.test/projects/42')

      expect(described_class.warehouse_reports).not_to include(entry)
    end

    it 'includes a Nightly Census sub-route referred from the report itself' do
      entry = log(path: '/censuses/date_range', referrer: 'https://hmis-warehouse.dev.test/censuses')

      expect(described_class.warehouse_reports).to include(entry)
    end
  end
end
