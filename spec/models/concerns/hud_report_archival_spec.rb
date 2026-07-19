###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReportArchival, type: :model do
  let(:report) do
    HudReports::ReportInstance.create!(
      report_name: 'Test HUD Report',
      user_id: User.system_user.id,
      state: 'Completed',
      completed_at: 30.days.ago,
      question_names: [],
    )
  end

  after do
    # Clean up any generator registrations made during this spec to avoid polluting other tests
    HudReportArchival.generator_registry.delete(report.report_name)
    HudReportArchival.generator_registry.delete('My Report - FY 9999')
  end

  describe '#archived?' do
    it 'returns false when archival_metadata is blank' do
      expect(report.archived?).to be false
    end

    it 'returns false when archived_at is missing from metadata' do
      report.update_column(:archival_metadata, { 'expected_files' => ['report_cells_csv'] })
      expect(report.archived?).to be false
    end

    it 'returns false when expected_files is empty' do
      report.update_column(:archival_metadata, { 'archived_at' => Time.current.iso8601 })
      expect(report.archived?).to be false
    end

    it 'returns false when listed files are not attached' do
      report.update_column(
        :archival_metadata,
        {
          'archived_at' => Time.current.iso8601,
          'expected_files' => ['report_cells_csv'],
        },
      )
      expect(report.archived?).to be false
    end

    it 'returns true when all expected files are attached' do
      report.update_column(
        :archival_metadata,
        {
          'archived_at' => Time.current.iso8601,
          'expected_files' => ['report_cells_csv'],
        },
      )
      report.report_cells_csv.attach(io: StringIO.new("col\nval"), filename: 'cells.csv', content_type: 'text/csv')
      expect(report.archived?).to be true
    end
  end

  describe '#purged?' do
    it 'returns false when purged_at is absent' do
      expect(report.purged?).to be false
    end

    it 'returns true when purged_at is present' do
      report.update_column(:archival_metadata, { 'purged_at' => Time.current.iso8601 })
      expect(report.purged?).to be true
    end
  end

  describe '#purge_eligible?' do
    it 'returns false when already purged' do
      report.update_column(
        :archival_metadata,
        {
          'purged_at' => Time.current.iso8601,
          'purge_eligible_at' => 1.day.ago.iso8601,
        },
      )
      expect(report.purge_eligible?).to be false
    end

    it 'returns false when purge_eligible_at is in the future' do
      report.update_column(:archival_metadata, { 'purge_eligible_at' => 1.day.from_now.iso8601 })
      expect(report.purge_eligible?).to be false
    end

    it 'returns true when purge_eligible_at has passed' do
      report.update_column(:archival_metadata, { 'purge_eligible_at' => 1.day.ago.iso8601 })
      expect(report.purge_eligible?).to be true
    end

    it 'returns false when no purge_eligible_at and completed_at + 60 days is in the future' do
      report.update!(completed_at: 30.days.ago)
      expect(report.purge_eligible?).to be false
    end

    it 'returns true when no purge_eligible_at and completed_at + 60 days has passed' do
      report.update!(completed_at: 61.days.ago)
      expect(report.purge_eligible?).to be true
    end
  end

  describe '#update_archival_metadata' do
    it 'merges a new key without destroying existing keys' do
      report.update_column(:archival_metadata, { 'existing' => 'value' })
      report.update_archival_metadata('new_key', 'new_value')
      report.reload
      expect(report.archival_metadata['existing']).to eq('value')
      expect(report.archival_metadata['new_key']).to eq('new_value')
    end

    it 'handles nil archival_metadata gracefully' do
      report.update_column(:archival_metadata, nil)
      expect { report.update_archival_metadata('k', 'v') }.not_to raise_error
      report.reload
      expect(report.archival_metadata['k']).to eq('v')
    end
  end

  describe '.register_archival_generator / .generator_registry' do
    it 'registers a generator class by report name' do
      fake_class = Class.new
      fake_class.define_singleton_method(:archival_csv_config) { |_| {} }
      HudReportArchival.register_archival_generator('My Report - FY 9999', fake_class)
      expect(HudReportArchival.generator_registry['My Report - FY 9999']).to eq(fake_class)
    end
  end

  describe '#archival_generator_klass' do
    it 'returns the registered generator for this report_name' do
      fake_class = Class.new
      fake_class.define_singleton_method(:archival_csv_config) { |_| {} }
      HudReportArchival.register_archival_generator(report.report_name, fake_class)
      expect(report.archival_generator_klass).to eq(fake_class)
    end

    it 'returns nil when no generator is registered for this report_name' do
      expect(HudReports::ReportInstance.new(report_name: 'Unknown Report').archival_generator_klass).to be_nil
    end

    it 'prefers generator_class from archival_metadata over the registry' do
      # Simulate a report archived under an old title that no longer matches any registry key.
      # The stored class name (String constant) must resolve correctly even after a title rename.
      report.update_column(:archival_metadata, { 'generator_class' => 'HudReports::ReportInstance' })
      expect(report.archival_generator_klass).to eq(HudReports::ReportInstance)
    end

    it 'falls back to registry lookup when generator_class is absent from metadata' do
      fake_class = Class.new
      fake_class.define_singleton_method(:archival_csv_config) { |_| {} }
      HudReportArchival.register_archival_generator(report.report_name, fake_class)
      # No generator_class key in metadata — legacy report or pre-archive state.
      report.update_column(:archival_metadata, {})
      expect(report.archival_generator_klass).to eq(fake_class)
    end
  end

  describe '#archival_status' do
    it 'returns { archived: false } when archived_at is absent' do
      expect(report.archival_status).to eq({ archived: false })
    end

    it 'returns a hash with expected keys when archived' do
      report.update_column(
        :archival_metadata,
        {
          'archived_at' => Time.current.iso8601,
          'purge_eligible_at' => 1.day.from_now.iso8601,
          'expected_files' => ['report_cells_csv'],
          'expected_file_count' => 1,
        },
      )
      status = report.archival_status
      expect(status).to include(
        :archived, :purged, :purge_eligible, :archived_at, :purge_eligible_at,
        :grace_period_days, :expected_file_count, :expected_files, :files
      )
      expect(status[:expected_files]).to eq(['report_cells_csv'])
      expect(status[:files]).to have_key('report_cells_csv')
    end
  end

  describe '#archival_csv_config' do
    it 'returns empty hash when no generator is registered for this report' do
      expect(HudReports::ReportInstance.new(report_name: 'Not Registered', question_names: []).archival_csv_config).to eq({})
    end

    it 'delegates to the registered generator' do
      expected = { report_cells_csv: { scope: -> {}, filename: -> { 'f.csv' }, delete_order: 1 } }
      fake_class = Class.new
      fake_class.define_singleton_method(:archival_csv_config) { |_| expected }
      HudReportArchival.register_archival_generator(report.report_name, fake_class)
      expect(report.archival_csv_config).to eq(expected)
    end
  end

  describe 'attachment declarations' do
    # These must exist without loading any driver generator — they are declared in HudReportArchival
    # itself, not via each driver's class_eval. This prevents the class-loading-order bug where
    # subclasses that snapshot _reflections before a generator is loaded would get AssociationNotFoundError
    # on destroy.
    expected_attachments = [
      :report_cells_csv, :universe_members_csv,
      :apr_clients_csv, :apr_living_situations_csv, :apr_ce_assessments_csv, :apr_ce_events_csv,
      :dq_clients_csv, :dq_living_situations_csv,
      :hic_projects_csv, :hic_project_cocs_csv, :hic_inventories_csv, :hic_organizations_csv, :hic_funders_csv,
      :lsa_summary_results_csv,
      :path_clients_csv,
      :pit_clients_csv,
      :spm_clients_csv, :spm_enrollments_csv, :spm_enrollment_links_csv, :spm_episodes_csv, :spm_returns_csv, :spm_bed_nights_csv
    ]

    expected_attachments.each do |name|
      it "declares #{name} on HudReports::ReportInstance without loading any driver generator" do
        expect(HudReports::ReportInstance.new).to respond_to(name)
      end
    end
  end

  describe 'destroy regression — subclass with own _reflections' do
    # Regression for the bug where HmisDataQualityTool::Report (a subclass that defines its own
    # has_many associations, causing it to snapshot _reflections before driver class_eval calls ran)
    # raised AssociationNotFoundError on destroy because inherited before_destroy callbacks tried to
    # look up driver-specific attachment associations not present in the subclass's snapshot.
    it 'HmisDataQualityTool::Report can be destroyed after APR generators are loaded' do
      report = HmisDataQualityTool::Report.create!(
        report_name: 'HMIS Data Quality Tool',
        user_id: User.system_user.id,
        question_names: [],
      )
      _ = HudApr::Generators::Apr::Fy2026::Generator
      expect { report.destroy! }.not_to raise_error
    end
  end

  describe 'purge_eligible scope' do
    let!(:eligible_report) do
      HudReports::ReportInstance.create!(
        report_name: 'Test',
        user_id: User.system_user.id,
        state: 'Completed',
        completed_at: 61.days.ago,
        question_names: [],
      )
    end

    let!(:ineligible_purged) do
      r = HudReports::ReportInstance.create!(
        report_name: 'Test',
        user_id: User.system_user.id,
        state: 'Completed',
        completed_at: 61.days.ago,
        question_names: [],
      )
      r.update_column(:archival_metadata, { 'purged_at' => Time.current.iso8601 })
      r
    end

    let!(:ineligible_recent) do
      HudReports::ReportInstance.create!(
        report_name: 'Test',
        user_id: User.system_user.id,
        state: 'Completed',
        completed_at: 30.days.ago,
        question_names: [],
      )
    end

    it 'includes reports past their grace period that have not been purged' do
      results = HudReports::ReportInstance.purge_eligible(60, Time.current)
      expect(results).to include(eligible_report)
    end

    it 'excludes already-purged reports' do
      results = HudReports::ReportInstance.purge_eligible(60, Time.current)
      expect(results).not_to include(ineligible_purged)
    end

    it 'excludes reports still within the grace period' do
      results = HudReports::ReportInstance.purge_eligible(60, Time.current)
      expect(results).not_to include(ineligible_recent)
    end

    it 'excludes reports that have a recorded purge failure' do
      failed_report = HudReports::ReportInstance.create!(
        report_name: 'Test',
        user_id: User.system_user.id,
        state: 'Completed',
        completed_at: 61.days.ago,
        question_names: [],
      )
      failed_report.update_column(:archival_metadata, { 'purge_failed_at' => Time.current.iso8601 })

      results = HudReports::ReportInstance.purge_eligible(60, Time.current)
      expect(results).not_to include(failed_report)
    end
  end
end
