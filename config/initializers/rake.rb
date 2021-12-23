require 'rake/task'
module Rake
  class Task
    alias orig_execute execute
    def execute(args = nil)
      orig_execute(args)
    rescue Exception => e
      ExceptionNotifier.notify_exception(e)
      # Re-raise so we get it in logs etc.
      raise e
    end
  end
end
