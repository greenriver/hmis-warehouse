# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentySix::Importer::ImportConcern, type: :model do
  # Use the existing User class that already includes the ImportConcern
  let(:test_class) { HmisCsvTwentyTwentySix::Importer::User }

  describe '.run_complex_validations! method with += operations' do
    it 'calls method that contains += operations for failures accumulation' do
      # Test the += operation from line 326: failures += check[:class].check_validity!(self, importer_log, **arguments)

      validation_check = double('validation_check')
      allow(validation_check).to receive(:check_validity!).and_return(['error1', 'error2'])

      allow(test_class).to receive(:complex_validations).and_return(
        [
          { class: validation_check },
        ],
      )

      importer_log = double('importer_log')
      summary = {
        'test_file.csv' => {
          'total_flags' => 3,
        },
      }
      allow(importer_log).to receive(:summary).and_return(summary)

      allow(Rails.logger).to receive(:info)

      filename = 'test_file.csv'

      # Call the actual method that contains the += operations
      result = test_class.run_complex_validations!(importer_log, filename)

      # Should return the accumulated failures
      expect(result).to eq(['error1', 'error2'])

      # The += operation should have updated the count
      expect(summary[filename]['total_flags']).to eq(5) # 3 + 2 failures
    end

    it 'calls method that exercises both += operations in sequence' do
      # Test both += operations: failures += ... and total_flags += ...

      validation_check1 = double('validation_check1')
      validation_check2 = double('validation_check2')
      allow(validation_check1).to receive(:check_validity!).and_return(['error1'])
      allow(validation_check2).to receive(:check_validity!).and_return(['error2', 'error3'])

      allow(test_class).to receive(:complex_validations).and_return(
        [
          { class: validation_check1 },
          { class: validation_check2 },
        ],
      )

      importer_log = double('importer_log')
      summary = {
        'multi_validation_file.csv' => {
          'total_flags' => 0,
        },
      }
      allow(importer_log).to receive(:summary).and_return(summary)

      allow(Rails.logger).to receive(:info)

      filename = 'multi_validation_file.csv'

      # This exercises both += operations:
      # 1. failures += check_validity! results (happens twice)
      # 2. total_flags += failures.count (happens once at end)
      result = test_class.run_complex_validations!(importer_log, filename)

      # Should return all accumulated failures
      expect(result).to eq(['error1', 'error2', 'error3'])

      # The final += operation should have added all failures to the count
      expect(summary[filename]['total_flags']).to eq(3) # 0 + 3 total failures
    end

    it 'handles validation checks with arguments parameter' do
      # Test += operations with validation arguments

      validation_check = double('validation_check')
      allow(validation_check).to receive(:check_validity!).and_return(['validation_error'])

      allow(test_class).to receive(:complex_validations).and_return(
        [
          { class: validation_check, arguments: { custom_arg: 'value' } },
        ],
      )

      importer_log = double('importer_log')
      summary = {
        'args_file.csv' => {
          'total_flags' => 5,
        },
      }
      allow(importer_log).to receive(:summary).and_return(summary)

      allow(Rails.logger).to receive(:info)

      filename = 'args_file.csv'

      result = test_class.run_complex_validations!(importer_log, filename)

      # Should pass arguments to the validation check
      expect(validation_check).to have_received(:check_validity!).with(
        test_class, importer_log, custom_arg: 'value'
      )

      expect(result).to eq(['validation_error'])
      expect(summary[filename]['total_flags']).to eq(6) # 5 + 1 failure
    end

    it 'handles empty validation results with += operations' do
      # Test += operations when check_validity! returns empty results

      validation_check = double('validation_check')
      allow(validation_check).to receive(:check_validity!).and_return([])

      allow(test_class).to receive(:complex_validations).and_return(
        [
          { class: validation_check },
        ],
      )

      importer_log = double('importer_log')
      summary = {
        'empty_file.csv' => {
          'total_flags' => 10,
        },
      }
      allow(importer_log).to receive(:summary).and_return(summary)

      allow(Rails.logger).to receive(:info)

      filename = 'empty_file.csv'

      result = test_class.run_complex_validations!(importer_log, filename)

      # += with empty array should not change anything
      expect(result).to eq([])
      expect(summary[filename]['total_flags']).to eq(10) # 10 + 0 failures
    end
  end

  describe 'method calls that exercise string mutations' do
    it 'exercises apply_import_overrides method that feeds data to validations' do
      override = double('override')
      allow(override).to receive(:apply).with({ data: 'test' }).and_return({ data: 'modified' })
      allow(override).to receive(:update)

      allow(test_class).to receive(:import_overrides).and_return([override])

      row = { data: 'test' }

      result = test_class.apply_import_overrides(row)

      expect(result).to eq({ data: 'modified' })
      expect(override).to have_received(:update).with(last_used_on: Date.current)
    end

    it 'creates new instance without error' do
      # Test that the concern can be included
      expect(test_class.ancestors).to include(HmisCsvTwentyTwentySix::Importer::ImportConcern)
    end
  end
end
