# frozen_string_literal: true

# A generic registry for thread-local data that needs to be accessible across threads
# or for monitoring purposes.
class ThreadSafeRegistry
  def initialize
    @mutex = Mutex.new
    @registry = {}.compare_by_identity
  end

  def register(value)
    @mutex.synchronize do
      @registry[Thread.current] = value
    end
  end

  def unregister
    @mutex.synchronize do
      @registry.delete(Thread.current)
    end
  end

  def current
    @mutex.synchronize do
      @registry[Thread.current]
    end
  end

  def reset!
    @mutex.synchronize do
      @registry = {}.compare_by_identity
    end
  end

  # Returns a copy of the internal registry for thread-safe iteration or inspection
  def all
    @mutex.synchronize do
      @registry.dup
    end
  end

  def synchronize(&block)
    @mutex.synchronize(&block)
  end
end
