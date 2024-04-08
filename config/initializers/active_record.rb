if Rails.env.test?
  # Fix deadlock during tests with multiple dbs. Looks like this should be patched in rails 7.1
  # https://github.com/rails/rails/pull/46661
  TodoOrDie('delete monkeypatch upgrade to >= rails 7.0', if: Rails.version !~ /\A7\.0/)
  class ActiveSupportConcurrencyNullLock
    def synchronize
      yield
    end
  end

  module ActiveRecordConnectionAdaptersLockPatch
    def initialize(...)
      super
      @lock = ActiveSupportConcurrencyNullLock.new
    end
  end

  ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(ActiveRecordConnectionAdaptersLockPatch)
end
