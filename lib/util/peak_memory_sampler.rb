# frozen_string_literal: true

require 'get_process_mem'

# Samples peak memory usage of a block of code using a polling thread.
# This is a lightweight alternative to memory_profiler for environments
# where profiling overhead should be minimized.
module PeakMemorySampler
  def self.current_mem_bytes
    GetProcessMem.new.bytes
  end

  # @return [Hash] Memory usage statistics:
  #   - peak_memory_bytes: [Integer] Maximum absolute memory usage during execution
  #   - relative_peak_memory_bytes: [Integer] Peak memory minus initial memory (memory growth)
  #   - retained_memory_bytes: [Integer] Memory difference after GC (memory not freed, leaks)
  def self.profile(poll_interval: 0.1)
    raise ArgumentError, 'a block is required' unless block_given?

    initial_memory_bytes = current_mem_bytes
    monitor_state = { running: true, peak_memory_bytes: initial_memory_bytes }
    mutex = Mutex.new

    monitor_thread = Thread.new do
      while mutex.synchronize { monitor_state[:running] }
        current_mem = current_mem_bytes
        mutex.synchronize do
          monitor_state[:peak_memory_bytes] = current_mem if current_mem > monitor_state[:peak_memory_bytes]
        end
        sleep(poll_interval)
      end
      # One final check after the loop to catch a last-second spike
      current_mem = current_mem_bytes
      mutex.synchronize do
        monitor_state[:peak_memory_bytes] = current_mem if current_mem > monitor_state[:peak_memory_bytes]
      end
    end

    begin
      yield
      peak_memory = mutex.synchronize { monitor_state[:peak_memory_bytes] }

      # Force garbage collection and measure retained memory
      GC.start
      final_memory_bytes = current_mem_bytes

      {
        peak_memory_bytes: peak_memory,
        relative_peak_memory_bytes: peak_memory - initial_memory_bytes,
        retained_memory_bytes: final_memory_bytes - initial_memory_bytes,
      }
    ensure
      # This ensures the monitor stops even if the block raises an error
      mutex.synchronize { monitor_state[:running] = false }
      # Wait for the thread to finish its current loop and exit
      monitor_thread.join
    end
  end
end
