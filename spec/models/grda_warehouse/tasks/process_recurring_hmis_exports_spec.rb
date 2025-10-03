# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ProcessRecurringHmisExports, type: :model do
  let(:task) { described_class.new }

  describe '#run!' do
    it 'executes exports that are due' do
      due_export = create(:recurring_hmis_export, updated_at: 2.days.ago)
      skip_export = create(:recurring_hmis_export, updated_at: Time.zone.now)

      allow(due_export).to receive(:should_run?).and_return(true)
      allow(skip_export).to receive(:should_run?).and_return(false)

      allow(task).to receive(:recurring_exports_scope).and_return([due_export, skip_export])

      expect(due_export).to receive(:run)
      expect(skip_export).not_to receive(:run)

      task.run!
    end

    it 'uses updated filter options when running exports' do
      # Create a recurring export with custom filter options
      recurring_export = create(
        :recurring_hmis_export,
        updated_at: 2.days.ago,
        reporting_range: 'n_days',
        reporting_range_days: 30,
        options: {
          'version' => '2026',
          'source_type' => 3,
          'hash_status' => 4,
          'period_type' => 1,
          'include_deleted' => true,
          'faked_pii' => true,
          'confidential' => true,
          'enforce_project_date_scope' => true,
          'project_ids' => ['1', '2', '3'],
          'project_group_ids' => ['4', '5'],
          'organization_ids' => ['6', '7'],
          'data_source_ids' => ['8', '9'],
          'coc_codes' => ['XX-500'],
          'custom_file_types' => ['CustomGender', 'CustomSexualOrientation'],
          'start_date' => 1.year.ago.to_date,
          'end_date' => Date.current,
        },
      )

      allow(recurring_export).to receive(:should_run?).and_return(true)
      allow(task).to receive(:recurring_exports_scope).and_return([recurring_export])

      # Capture the options_for_job that gets passed to the job
      job_options = nil
      allow_any_instance_of(Filters::HmisExport).to receive(:schedule_job) do |filter|
        job_options = filter.send(:options_for_job)
      end

      allow(Filters::HmisExport).to receive(:new).and_wrap_original do |method, *args|
        filter = method.call(*args)
        allow(filter).to receive(:effective_project_ids).and_return([1, 2, 3])
        filter
      end

      # Time travel to test date adjustment
      travel_to 5.days.from_now do
        # Run the actual task
        task.run!

        # Verify that the job options include all the custom filter options
        expect(job_options[:version]).to eq('2026')
        expect(job_options[:period_type]).to eq(1)
        expect(job_options[:directive]).to eq(2)
        expect(job_options[:hash_status]).to eq(4)
        expect(job_options[:include_deleted]).to eq(true)
        expect(job_options[:faked_pii]).to eq(true)
        expect(job_options[:confidential]).to eq(true)
        expect(job_options[:enforce_project_date_scope]).to eq(true)
        expect(job_options[:recurring_hmis_export_id]).to eq(recurring_export.id)
        # Project resolution requires substantial data setup in the test environment.
        # We verify option propagation via the options hash instead.
        expect(job_options[:options]).to be_a(Hash)

        # Verify that the options hash contains all the filter settings
        options = job_options[:options]
        expect(options[:version]).to eq('2026')
        expect(options[:source_type]).to eq(3)
        expect(options[:hash_status]).to eq(4)
        expect(options[:period_type]).to eq(1)
        expect(options[:include_deleted]).to eq(true)
        expect(options[:faked_pii]).to eq(true)
        expect(options[:confidential]).to eq(true)
        expect(options[:enforce_project_date_scope]).to eq(true)
        expect(options[:project_ids]).to eq(['1', '2', '3'])
        expect(options[:project_group_ids]).to eq(['4', '5'])
        expect(options[:organization_ids]).to eq(['6', '7'])
        expect(options[:data_source_ids]).to eq(['8', '9'])
        expect(options[:coc_codes]).to eq(['XX-500'])
        expect(options[:custom_file_types]).to eq(['CustomGender', 'CustomSexualOrientation'])

        # Verify that dates were adjusted based on reporting_range
        # Since we're 5 days in the future and reporting_range is 'n_days' with 30 days,
        # start_date should be 30 days before the current date (5 days from now)
        expected_end_date = Date.current
        expected_start_date = expected_end_date - 30.days
        expect(job_options[:start_date]).to eq(expected_start_date.to_date.to_fs(:db))
        expect(job_options[:end_date]).to eq(expected_end_date.to_date.to_fs(:db))
        expect(options[:start_date]).to eq(expected_start_date)
        expect(options[:end_date]).to eq(expected_end_date)
      end
    end
  end
end
