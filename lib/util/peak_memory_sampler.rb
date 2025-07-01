# frozen_string_literal: true

require 'get_process_mem'

# Samples peak memory usage of a block of code using a polling thread.
# This is a lightweight alternative to memory_profiler for environments
# where profiling overhead should be minimized.
module PeakMemorySampler
  def self.current_mem_bytes
    GetProcessMem.new.bytes
  end

  # @return [Hash] with keys :result and :peak_memory_bytes
  def self.profile(poll_interval: 0.5)
    raise ArgumentError, 'a block is required' unless block_given?

    initial_memory_bytes = current_mem_bytes
    monitor_state = { running: true, peak_memory_bytes: initial_memory_bytes }

    monitor_thread = Thread.new do
      while monitor_state[:running]
        current_mem = current_mem_bytes
        monitor_state[:peak_memory_bytes] = current_mem if current_mem > monitor_state[:peak_memory_bytes]
        sleep(poll_interval)
      end
      # One final check after the loop to catch a last-second spike
      current_mem = current_mem_bytes
      monitor_state[:peak_memory_bytes] = current_mem if current_mem > monitor_state[:peak_memory_bytes]
    end

    begin
      yield
      peak_memory = monitor_state[:peak_memory_bytes]
      {
        peak_memory_bytes: peak_memory,
        relative_memory_bytes: peak_memory - initial_memory_bytes,
      }
    ensure
      # This ensures the monitor stops even if the block raises an error
      monitor_state[:running] = false
      # Wait for the thread to finish its current loop and exit
      monitor_thread.join
    end
  end
end
