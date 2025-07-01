# frozen_string_literal: false

require 'rails_helper'

RSpec.describe PeakMemorySampler do
  describe '.profile' do
    it 'captures the approximate peak memory of the process' do
      GC.start
      base_mem = GetProcessMem.new.bytes
      array_size = 10 * 1024 * 1024 # 10MB array

      profiled = described_class.profile do
        ['a'] * array_size # rubocop:disable Lint/Void

        # The sampler thread runs in the background. Sleep to capture the peak allocation.
        sleep(0.6)
      end

      peak_mem = profiled[:peak_memory_bytes]
      relative_mem = profiled[:relative_peak_memory_bytes]

      expect(peak_mem).to be >= (base_mem)
      # Assert that the recorded peak memory is at least the size of the
      # baseline memory plus some fraction of the array
      expect(relative_mem).to be >= array_size * 0.9

      # Assert that retained memory is tracked
      retained_mem = profiled[:retained_memory_bytes]
      expect(retained_mem).to be >= 0
    end

    it 'returns a value for peak memory if a no-op is given' do
      profiled = described_class.profile { true }
      expect(profiled[:peak_memory_bytes]).to be > 0
    end

    it 'raises an error if no block is given' do
      expect do
        described_class.profile
      end.to raise_error(ArgumentError, 'a block is required')
    end
  end
end
