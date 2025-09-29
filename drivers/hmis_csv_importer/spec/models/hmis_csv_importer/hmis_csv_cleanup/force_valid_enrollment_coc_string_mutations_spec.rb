# frozen_string_literal: false

require 'rails_helper'

RSpec.describe HmisCsvImporter::HmisCsvCleanup::ForceValidEnrollmentCoc, type: :model do
  let(:importer_log) { double('importer_log', id: 1) }
  let(:cleanup) { described_class.new(importer_log) }

  describe '#cleanup! method with upcase! and << operations' do
    it 'calls method that contains upcase! operations for CoC code fixing' do
      # Test the upcase! operation from line 22: enrollment.EnrollmentCoC.upcase!

      # Create test enrollment with lowercase CoC code
      enrollment = double('enrollment')
      allow(enrollment).to receive(:EnrollmentCoC).and_return('ca-501')
      allow(enrollment).to receive(:EnrollmentCoC=)
      allow(enrollment).to receive(:set_source_hash)

      # Mock the upcase! method to track calls
      coc_code = 'ca-501'
      allow(enrollment).to receive(:EnrollmentCoC).and_return(coc_code)
      allow(coc_code).to receive(:upcase!).and_return('CA-501')
      allow(coc_code).to receive(:match?).with(/^[a-z]{2}[0-9]{3}$/i).and_return(false)
      allow(coc_code).to receive(:match?).with(/^[a-z]{2}-[0-9]{3}$/i).and_return(true)
      allow(coc_code).to receive(:present?).and_return(true)

      # Mock valid_coc? to trigger processing
      allow(::HudHelper.util).to receive(:valid_coc?).with('ca-501').and_return(false)
      allow(::HudHelper.util).to receive(:valid_coc?).with('CA-501').and_return(true)

      # Mock enrollment scope
      enrollment_scope = double('enrollment_scope')
      allow(cleanup).to receive(:enrollment_scope).and_return(enrollment_scope)
      allow(enrollment_scope).to receive(:find_each).and_yield(enrollment)

      # Mock enrollment source and import
      enrollment_source = double('enrollment_source')
      allow(cleanup).to receive(:enrollment_source).and_return(enrollment_source)
      allow(enrollment_source).to receive(:import)
      allow(cleanup).to receive(:conflict_target).and_return({})

      # Call the actual method that contains the upcase! operation
      expect { cleanup.cleanup! }.not_to raise_error

      # Should have called upcase! on the EnrollmentCoC string
      expect(coc_code).to have_received(:upcase!)
    end

    it 'calls method that contains << operations for batch building' do
      # Test the << operation from line 28: enrollment_batch << enrollment

      enrollment1 = double('enrollment1')
      enrollment2 = double('enrollment2')

      # Set up enrollments that need processing
      [enrollment1, enrollment2].each do |enrollment|
        allow(enrollment).to receive(:EnrollmentCoC).and_return('invalid_coc')
        allow(enrollment).to receive(:EnrollmentCoC=)
        allow(enrollment).to receive(:set_source_hash)
      end

      # Mock HudHelper to indicate CoC codes are invalid
      allow(::HudHelper.util).to receive(:valid_coc?).and_return(false)

      # Mock enrollment scope to yield multiple enrollments
      enrollment_scope = double('enrollment_scope')
      allow(cleanup).to receive(:enrollment_scope).and_return(enrollment_scope)
      allow(enrollment_scope).to receive(:find_each).and_yield(enrollment1).and_yield(enrollment2)

      # Mock import method to capture the batch
      enrollment_source = double('enrollment_source')
      allow(cleanup).to receive(:enrollment_source).and_return(enrollment_source)
      allow(enrollment_source).to receive(:import) do |batch, _options|
        # Should receive array built with << operations containing both enrollments
        expect(batch).to include(enrollment1, enrollment2)
        expect(batch.length).to eq(2)
      end
      allow(cleanup).to receive(:conflict_target).and_return({})

      # This will exercise the << operations as enrollments are added to the batch
      expect { cleanup.cleanup! }.not_to raise_error
    end

    it 'exercises both upcase! and << operations in processing flow' do
      # Test both string mutations in the same processing flow

      # Create enrollment with lowercase CoC that matches pattern
      enrollment = double('enrollment')
      coc_code = 'ny-600'
      allow(enrollment).to receive(:EnrollmentCoC).and_return(coc_code)
      allow(enrollment).to receive(:EnrollmentCoC=)
      allow(enrollment).to receive(:set_source_hash)

      # Mock the string operations
      allow(coc_code).to receive(:match?).with(/^[a-z]{2}[0-9]{3}$/i).and_return(false)
      allow(coc_code).to receive(:match?).with(/^[a-z]{2}-[0-9]{3}$/i).and_return(true)
      allow(coc_code).to receive(:upcase!).and_return('NY-600')
      allow(coc_code).to receive(:present?).and_return(true)

      # Mock valid_coc? to trigger upcase! operation
      allow(::HudHelper.util).to receive(:valid_coc?).with('ny-600').and_return(false)
      allow(::HudHelper.util).to receive(:valid_coc?).with('NY-600').and_return(true)

      enrollment_scope = double('enrollment_scope')
      allow(cleanup).to receive(:enrollment_scope).and_return(enrollment_scope)
      allow(enrollment_scope).to receive(:find_each).and_yield(enrollment)

      enrollment_source = double('enrollment_source')
      allow(cleanup).to receive(:enrollment_source).and_return(enrollment_source)
      allow(enrollment_source).to receive(:import) do |batch, _options|
        # Should receive array built with << operation containing the processed enrollment
        expect(batch).to include(enrollment)
        expect(batch.length).to eq(1)
      end
      allow(cleanup).to receive(:conflict_target).and_return({})

      # This exercises both upcase! and << operations
      expect { cleanup.cleanup! }.not_to raise_error

      expect(coc_code).to have_received(:upcase!)
    end

    it 'exercises << operation with multiple enrollment processing scenarios' do
      # Test << operation with various enrollment processing paths

      # Valid enrollment - should be skipped (no << operation)
      valid_enrollment = double('valid_enrollment')
      allow(valid_enrollment).to receive(:EnrollmentCoC).and_return('CA-501')
      allow(::HudHelper.util).to receive(:valid_coc?).with('CA-501').and_return(true)

      # Invalid enrollment - should be processed and added with << operation
      invalid_enrollment = double('invalid_enrollment')
      allow(invalid_enrollment).to receive(:EnrollmentCoC).and_return('invalid')
      allow(invalid_enrollment).to receive(:EnrollmentCoC=)
      allow(invalid_enrollment).to receive(:set_source_hash)
      allow(::HudHelper.util).to receive(:valid_coc?).with('invalid').and_return(false)

      enrollment_scope = double('enrollment_scope')
      allow(cleanup).to receive(:enrollment_scope).and_return(enrollment_scope)
      allow(enrollment_scope).to receive(:find_each).and_yield(valid_enrollment).and_yield(invalid_enrollment)

      enrollment_source = double('enrollment_source')
      allow(cleanup).to receive(:enrollment_source).and_return(enrollment_source)
      allow(enrollment_source).to receive(:import) do |batch, _options|
        # Should only contain the invalid enrollment (valid one was skipped)
        expect(batch).to include(invalid_enrollment)
        expect(batch).not_to include(valid_enrollment)
        expect(batch.length).to eq(1)
      end
      allow(cleanup).to receive(:conflict_target).and_return({})

      expect { cleanup.cleanup! }.not_to raise_error
    end
  end

  describe 'method calls that exercise string mutations' do
    it 'exercises enrollment_scope method that feeds into cleanup!' do
      enrollment_source = double('enrollment_source')
      allow(cleanup).to receive(:enrollment_source).and_return(enrollment_source)

      scope_chain = double('scope_chain')
      allow(enrollment_source).to receive(:where).with(importer_log_id: 1).and_return(scope_chain)
      allow(scope_chain).to receive(:where).and_return(scope_chain)

      cleanup.enrollment_scope

      expect(enrollment_source).to have_received(:where).with(importer_log_id: 1)
    end

    it 'creates new instance without error' do
      cleanup_instance = described_class.new(importer_log)

      expect(cleanup_instance).to be_a(described_class)
    end
  end
end
