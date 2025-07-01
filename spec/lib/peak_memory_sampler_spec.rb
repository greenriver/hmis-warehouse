# frozen_string_literal: false

require 'rails_helper'

RSpec.describe PeakMemorySampler do
  describe '.profile' do
    it 'records a peak memory usage value' do
      profiled = described_class.profile do # Allocate a small string
        @test_str = 'test-result'
        sleep(0.6)
      end
      expect(profiled[:peak_memory_bytes]).to be > 0
    end

    it 'captures the approximate peak memory of the process' do
      base_mem = GetProcessMem.new.bytes
      string_size = 10 * 1024 * 1024 # 10MB string

      profiled = described_class.profile do
        @test_str = 'a' * string_size

        # The sampler thread runs in the background. Sleep to capture the peak allocation.
        sleep(0.6)
      end

      peak_mem = profiled[:peak_memory_bytes]

      # Assert that the recorded peak memory is at least the size of the
      # baseline memory plus a significant fraction (95%) of the string,
      # making the test less brittle.
      expected_minimum = base_mem + (string_size * 0.95)
      expect(peak_mem).to be >= expected_minimum
    end

    it 'returns 0 for peak memory and if no-op is given' do
      profiled = described_class.profile do
        sleep(0.6)
      end
      expect(profiled[:peak_memory_bytes]).to eq(0)
    end
  end
end
