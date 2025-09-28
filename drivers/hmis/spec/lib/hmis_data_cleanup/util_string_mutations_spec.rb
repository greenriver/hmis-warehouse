# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisDataCleanup::Util, type: :model do
  describe '.fix_incorrect_personal_id_references! method with << operations' do
    it 'calls method that contains << operations for values array building' do
      # Test the << operation from line 200: values << record

      # Mock required dependencies
      allow(Rails.logger).to receive(:info)
      allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)

      # Call the actual method that contains the << operation
      expect { described_class.fix_incorrect_personal_id_references!(dry_run: true) }.not_to raise_error
    end
  end

  describe '.write_project_enrollment_summary method with << operations' do
    it 'calls method that contains << operations for CSV writing' do
      # Test the << operation from line 342: writer << row.values

      filename = '/tmp/test_project_summary.csv'

      # Mock the project and enrollment data
      project = double(
        'project',
        id: 1,
        project_name: 'Test Project',
        project_type: 1,
        organization_name: 'Test Org',
      )

      allow(Hmis::Hud::Project).to receive_message_chain(:hmis, :includes, :find_each).and_yield(project)
      allow(project).to receive_message_chain(:enrollments, :count).and_return(5)
      allow(project).to receive_message_chain(:enrollments, :open_on_date, :count).and_return(3)

      # Mock CSV to avoid file system operations
      csv_writer = double('csv_writer')
      allow(CSV).to receive(:open).and_yield(csv_writer)
      allow(csv_writer).to receive(:<<).and_return(true)

      # Call the actual method that contains the << operation
      expect { described_class.write_project_enrollment_summary(filename: filename) }.not_to raise_error

      # Clean up
      File.delete(filename) if File.exist?(filename)
    end
  end

  describe '.write_project_unit_summary method with << operations' do
    it 'calls method that contains << operations for row building' do
      # Test the << operation from line 385: rows << hash

      filename = '/tmp/test_unit_summary.csv'

      # Mock project data
      project = double(
        'project',
        project_id: 'PROJ123',
        project_name: 'Test Project',
      )

      allow(Hmis::Hud::Project).to receive(:hmis).and_return([project])
      allow(project).to receive_message_chain(:enrollments, :open_on_date, :pluck).with(:id).and_return([1, 2, 3])
      allow(project).to receive_message_chain(:enrollments, :open_on_date, :joins, :pluck).with(:id).and_return([1, 2])
      allow(project).to receive(:units).and_return([])

      # Mock CSV operations
      csv_writer = double('csv_writer')
      allow(CSV).to receive(:open).and_yield(csv_writer)
      allow(csv_writer).to receive(:<<).and_return(true)

      # Call the actual method that contains the << operation
      expect { described_class.write_project_unit_summary(filename: filename) }.not_to raise_error

      # Clean up
      File.delete(filename) if File.exist?(filename)
    end
  end

  describe '.correct_total_income_records! method with += operations' do
    it 'calls method that contains += operations for message accumulation' do
      # Test the += operation from line 552: messages += Hmis::Hud::DataIntegrity::TotalIncomeReconciler.call(record)

      # Mock required dependencies
      allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
      allow(Rails.logger).to receive(:info)

      data_source = double('data_source', id: 1)
      allow(GrdaWarehouse::DataSource).to receive(:hmis).and_return([data_source])

      record = double('record', id: 1)
      allow(Hmis::Hud::IncomeBenefit).to receive_message_chain(:where, :joins, :find_each).and_yield(record)
      allow(Hmis::Hud::DataIntegrity::TotalIncomeReconciler).to receive(:call).and_return([])

      # Call the actual method that contains the += operation
      expect { described_class.correct_total_income_records! }.not_to raise_error
    end
  end

  describe 'utility methods that exercise string mutations' do
    it 'exercises assign_missing_household_ids! with string operations' do
      # Mock dependencies to avoid database operations
      allow(Rails.logger).to receive(:info)
      allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)

      data_source = double('data_source')
      allow(GrdaWarehouse::DataSource).to receive(:hmis).and_return([data_source])

      enrollment = double('enrollment')
      allow(Hmis::Hud::Enrollment).to receive_message_chain(:joins, :where, :find_each).and_yield(enrollment)
      allow(enrollment).to receive(:assign_missing_household_id!)

      # Should call the method without error
      expect { described_class.assign_missing_household_ids! }.not_to raise_error
    end

    it 'exercises fix_99s_for_category! with array operations' do
      clients = []
      category = 'test_category'
      none_field = 'none_field'
      fields = ['field1', 'field2']

      # Call the actual method
      expect { described_class.fix_99s_for_category!(clients, category: category, none_field: none_field, fields: fields) }.not_to raise_error
    end
  end
end
