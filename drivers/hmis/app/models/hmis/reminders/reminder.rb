module Hmis
  module Reminders
    Reminder = Struct.new(:id, :topic, :due_date, :overdue, :enrollment, keyword_init: true) do
      PLACEHOLDER_DATE = Date.current + 100.years
      def sort_order
        [due_date || PLACEHOLDER_DATE, id]
      end
    end
  end
end
