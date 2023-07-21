module Hmis
  module Reminders
    Reminder = Struct.new(:id, :event_id, :enrollment_id, :due_date, :description, keyword_init: true) do
      def id
        "#{enrollment_id}.#{event_id}"
      end
    end
  end
end
