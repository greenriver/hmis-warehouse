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

  describe '.warehouse_report_conditions' do
    def condition_for(url)
      described_class.warehouse_report_conditions.find { |report_url, _| report_url == url }.last
    end

    # 'warehouse_reports/chronic' is a string-prefix of the sibling report
    # 'warehouse_reports/chronic_housed' -- a bare `path LIKE '/url%'` default would let Chronic's
    # condition also match Chronic Housed's traffic, misattributing it (first-match-wins in the
    # CASE UsageSummary builds from this same list). The default must require a `/`, `?`, or
    # end-of-string boundary right after the url, not just any continuation.
    it "doesn't let one report's condition match a sibling report whose url is a string-prefix of it" do
      housed_entry = log(path: '/warehouse_reports/chronic_housed/42')

      expect(described_class.where(condition_for('warehouse_reports/chronic'))).not_to include(housed_entry)
      expect(described_class.where(condition_for('warehouse_reports/chronic_housed'))).to include(housed_entry)
    end

    it 'still matches the exact bare url with no trailing segment' do
      entry = log(path: '/warehouse_reports/chronic')

      expect(described_class.where(condition_for('warehouse_reports/chronic'))).to include(entry)
    end

    it 'still matches the url followed by a query string' do
      entry = log(path: '/warehouse_reports/chronic?foo=bar')

      expect(described_class.where(condition_for('warehouse_reports/chronic'))).to include(entry)
    end
  end

  describe '#reporting_path' do
    it 'mirrors the first REPORTING_PATH_LENGTH characters of path on save' do
      long_path = "/warehouse_reports/chronic/#{'a' * described_class::REPORTING_PATH_LENGTH}"
      entry = log(path: long_path)

      expect(entry.reload.reporting_path).to eq(long_path.first(described_class::REPORTING_PATH_LENGTH))
    end

    it 'does not modify the stored path of an entry longer than REPORTING_PATH_LENGTH' do
      long_path = "/warehouse_reports/chronic/#{'a' * described_class::REPORTING_PATH_LENGTH}"
      entry = log(path: long_path)

      expect(entry.reload.path).to eq(long_path)
    end
  end

  describe '.backfill_reporting_path!' do
    # Existing rows predate the reporting_path column (see
    # db/migrate/20260827150000_add_reporting_path_to_activity_logs.rb) and this runs out of band
    # via TaskQueue rather than in that migration; simulate that pre-backfill state directly since
    # the before_save callback would otherwise always populate reporting_path on save.
    it 'sets reporting_path from path for a row that predates the column' do
      entry = log(path: '/warehouse_reports/chronic/1234')
      entry.update_column(:reporting_path, nil)

      described_class.backfill_reporting_path!

      expect(entry.reload.reporting_path).to eq('/warehouse_reports/chronic/1234')
    end

    it 'truncates to REPORTING_PATH_LENGTH characters for a path longer than that' do
      long_path = "/warehouse_reports/chronic/#{'a' * (described_class::REPORTING_PATH_LENGTH * 2)}"
      entry = log(path: long_path)
      entry.update_column(:reporting_path, nil)

      described_class.backfill_reporting_path!

      expect(entry.reload.reporting_path).to eq(long_path.first(described_class::REPORTING_PATH_LENGTH))
    end

    it 'leaves a row with a reporting_path already set untouched' do
      entry = log(path: '/warehouse_reports/chronic/1234')
      entry.update_column(:reporting_path, '/something/else')

      described_class.backfill_reporting_path!

      expect(entry.reload.reporting_path).to eq('/something/else')
    end
  end

  describe '.warehouse_reports with a path longer than REPORTING_PATH_LENGTH' do
    # `path` can't be indexed directly (see db/migrate/20260827150000_add_reporting_path_to_activity_logs.rb
    # for why), but report urls are always far shorter than REPORTING_PATH_LENGTH, so a matching
    # entry is still counted correctly however long the real path's query string runs beyond that --
    # unlike the excluded-outlier approach this replaced, oversized report traffic isn't dropped.
    it 'still includes a matching entry whose path runs well past REPORTING_PATH_LENGTH' do
      long_path = "/warehouse_reports/chronic/#{'a' * (described_class::REPORTING_PATH_LENGTH * 2)}"
      entry = log(path: long_path)

      expect(described_class.warehouse_reports).to include(entry)
    end
  end
end
