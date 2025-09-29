# frozen_string_literal: false

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwenty::HmisCsvCleanup::ForceValidEnrollmentCoc, type: :model do
  let(:importer_log) { double('importer_log', id: 1) }
  let(:cleanup) { described_class.new(importer_log) }

  describe '#cleanup! method with upcase! and << operations' do
    it 'contains upcase! and << operations but raises exception before reaching them' do
      # Test the method that contains upcase! operation from line 24: e_coc.CoCCode.upcase!
      # and << operation from line 30: enrollment_coc_batch << e_coc
      # However, this method raises an exception on line 15, making these operations unreachable

      # Mock enrollment_coc_scope to avoid database queries
      enrollment_coc_scope = double('enrollment_coc_scope')
      allow(cleanup).to receive(:enrollment_coc_scope).and_return(enrollment_coc_scope)
      allow(enrollment_coc_scope).to receive(:find_each)

      # The method should raise an exception before any string mutations occur
      expect { cleanup.cleanup! }.to raise_error(RuntimeError, 'HmisCsvTwentyTwenty::HmisCsvCleanup::ForceValidEnrollmentCoc is no longer active')

      # Verify that find_each was never called due to the early exception
      expect(enrollment_coc_scope).not_to have_received(:find_each)
    end

    it 'method structure shows unreachable string mutations after exception' do
      # While the method contains string mutations, they are unreachable due to the exception
      # This test documents the presence of the string mutation patterns for frozen string literal conversion

      # The method contains these string mutations that would fail with frozen strings:
      # Line 24: e_coc.CoCCode.upcase! if e_coc.CoCCode.match?(/^[a-z]{2}-[0-9]{3}$/i)
      # Line 30: enrollment_coc_batch << e_coc

      # However, line 15 raises an exception: 'HmisCsvTwentyTwenty::HmisCsvCleanup::ForceValidEnrollmentCoc is no longer active'

      # Test that the exception occurs immediately
      expect { cleanup.cleanup! }.to raise_error(/no longer active/)
    end

    it 'enrollment_coc_scope method works independently' do
      # Test supporting method that doesn't raise exceptions

      enrollment_coc_source = double('enrollment_coc_source')
      allow(cleanup).to receive(:enrollment_coc_source).and_return(enrollment_coc_source)

      scope_chain = double('scope_chain')
      allow(enrollment_coc_source).to receive(:where).with(importer_log_id: 1).and_return(scope_chain)
      allow(scope_chain).to receive(:where).and_return(scope_chain)

      cleanup.enrollment_coc_scope

      expect(enrollment_coc_source).to have_received(:where).with(importer_log_id: 1)
    end
  end

  describe 'method calls that exercise class structure' do
    it 'exercises enrollment_coc_source method' do
      result = cleanup.enrollment_coc_source

      # Should return the expected class
      expect(result).to eq(HmisCsvTwentyTwenty::Importer::EnrollmentCoc)
    end

    it 'creates new instance without error' do
      cleanup_instance = described_class.new(importer_log)

      expect(cleanup_instance).to be_a(described_class)
    end

    it 'provides class description and enable configuration' do
      # Test class methods that support the cleanup infrastructure
      expect(described_class.description).to include('Fix Enrollment.CoCCode')
      expect(described_class.enable).to have_key(:import_cleanups)
    end
  end
end
