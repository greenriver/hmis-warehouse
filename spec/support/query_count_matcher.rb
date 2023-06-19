RSpec::Matchers.define :query_limit_lt do |expected|
  match do |block|
    query_count(&block) <= expected
  end

  if respond_to?(:failure_message)
    failure_message do |_actual|
      failure_text
    end

    failure_message_when_negated do |_actual|
      failure_text_negated
    end
  else
    failure_message_for_should do |_actual|
      failure_text
    end

    failure_message_for_should_not do |_actual|
      failure_text_negated
    end
  end

  def query_count(&block)
    @counter = 0

    counter = ->(_name, _started, _finished, _unique_id, payload) {
      @counter += 1 unless ['CACHE', 'SCHEMA'].include?(payload[:name])
    }

    ActiveSupport::Notifications.subscribed(
      counter,
      'sql.active_record',
      &block
    )

    @counter
  end

  def supports_block_expectations?
    true
  end

  def failure_text
    "Expected to not to run more than #{expected} queries, got #{@counter}"
  end

  def failure_text_negated
    "Expected to run more than #{expected} queries, got #{@counter}"
  end
end
