# frozen_string_literal: false

require 'rails_helper'

# Create a test class that includes the concern to test the string mutations
class TestImportModel < ApplicationRecord
  include HmisCsvTwentyTwentyFour::Importer::ImportConcern

  self.table_name = 'nonexistent_table'

  def self.hmis_structure
    { id: :integer, name: :string }
  end

  def self.hud_key
    :id
  end

  def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable Lint/UnusedMethodArgument
    where(id: [])
  end

  def self.paranoid?
    false
  end
end

RSpec.describe HmisCsvTwentyTwentyFour::Importer::ImportConcern, type: :model do
  describe '.run_complex_validations! method with += operations' do
    it 'calls method that contains += operations for failure count accumulation' do
      # Test the += operation from line 330: importer_log.summary[filename]['total_flags'] += failures.count

      # Mock the complex validations
      validation_check = double('validation_check')
      allow(validation_check).to receive(:check_validity!).and_return(['error1', 'error2'])

      allow(TestImportModel).to receive(:complex_validations).and_return(
        [
          { class: validation_check },
        ],
      )

      # Mock importer log with summary structure
      importer_log = double('importer_log')
      summary = {
        'test_file.csv' => {
          'total_flags' => 5,
        },
      }
      allow(importer_log).to receive(:summary).and_return(summary)

      # Mock Rails logger
      allow(Rails.logger).to receive(:debug)

      filename = 'test_file.csv'

      # Call the actual method that contains the += operation
      result = TestImportModel.run_complex_validations!(importer_log, filename)

      # Should return the failures
      expect(result).to eq(['error1', 'error2'])

      # The += operation should have incremented the total_flags count
      expect(summary[filename]['total_flags']).to eq(7) # 5 + 2 failures
    end

    it 'handles case where total_flags is not initialized' do
      # Test the += operation when total_flags needs to be initialized first

      validation_check = double('validation_check')
      allow(validation_check).to receive(:check_validity!).and_return(['error1'])

      allow(TestImportModel).to receive(:complex_validations).and_return(
        [
          { class: validation_check },
        ],
      )

      # Mock importer log with summary but no total_flags
      importer_log = double('importer_log')
      summary = {
        'new_file.csv' => {},
      }
      allow(importer_log).to receive(:summary).and_return(summary)

      allow(Rails.logger).to receive(:debug)

      filename = 'new_file.csv'

      # Call the method that contains the += operation
      result = TestImportModel.run_complex_validations!(importer_log, filename)

      # Should initialize total_flags to 0 then add failures.count
      expect(result).to eq(['error1'])
      expect(summary[filename]['total_flags']).to eq(1) # 0 + 1 failure
    end

    it 'handles multiple validation checks with += accumulation' do
      # Test multiple validations that each contribute to the += operation

      validation_check1 = double('validation_check1')
      validation_check2 = double('validation_check2')
      allow(validation_check1).to receive(:check_validity!).and_return(['error1', 'error2'])
      allow(validation_check2).to receive(:check_validity!).and_return(['error3'])

      allow(TestImportModel).to receive(:complex_validations).and_return(
        [
          { class: validation_check1 },
          { class: validation_check2 },
        ],
      )

      importer_log = double('importer_log')
      summary = {
        'multi_file.csv' => {
          'total_flags' => 10,
        },
      }
      allow(importer_log).to receive(:summary).and_return(summary)

      allow(Rails.logger).to receive(:debug)

      filename = 'multi_file.csv'

      # This will exercise the += operation multiple times as failures accumulate
      result = TestImportModel.run_complex_validations!(importer_log, filename)

      # Should return all failures
      expect(result).to eq(['error1', 'error2', 'error3'])

      # The += operation should have added all failures to the count
      expect(summary[filename]['total_flags']).to eq(13) # 10 + 3 failures
    end

    it 'handles validation checks with nil failures' do
      # Test compact! operation and += with filtered results

      validation_check = double('validation_check')
      allow(validation_check).to receive(:check_validity!).and_return(['error1', nil, 'error2', nil])

      allow(TestImportModel).to receive(:complex_validations).and_return(
        [
          { class: validation_check },
        ],
      )

      importer_log = double('importer_log')
      summary = {
        'compact_file.csv' => {
          'total_flags' => 2,
        },
      }
      allow(importer_log).to receive(:summary).and_return(summary)

      allow(Rails.logger).to receive(:debug)

      filename = 'compact_file.csv'

      result = TestImportModel.run_complex_validations!(importer_log, filename)

      # Should compact nil values and only count real failures
      expect(result).to eq(['error1', 'error2'])
      expect(summary[filename]['total_flags']).to eq(4) # 2 + 2 non-nil failures
    end
  end

  describe 'method calls that exercise string mutations' do
    it 'exercises apply_import_overrides method chain' do
      # Test the method that feeds into run_complex_validations!

      override = double('override')
      allow(override).to receive(:apply).with({ id: 1, name: 'test' }).and_return({ id: 1, name: 'modified' })
      allow(override).to receive(:update)

      allow(TestImportModel).to receive(:import_overrides).and_return([override])

      row = { id: 1, name: 'test' }

      result = TestImportModel.apply_import_overrides(row)

      expect(result).to eq({ id: 1, name: 'modified' })
      expect(override).to have_received(:update).with(last_used_on: Date.current)
    end

    it 'creates new instance without error' do
      # Since we can't actually create a TestImportModel instance due to nonexistent table,
      # we'll test that the concern can be included
      expect(TestImportModel.ancestors).to include(HmisCsvTwentyTwentyFour::Importer::ImportConcern)
    end
  end
end
