module Hmis
  module Reminders
    Reminder = Struct.new(:id, :topic, :due_date, :overdue, :enrollment, keyword_init: true) do
      def sort_order
        [due_date, id]
      end
    end
  end
end
