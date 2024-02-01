module Hmis
  module Reminders
    Reminder = Struct.new(:topic, :due_date, :overdue, :enrollment, :form_definition_id, :assessment_id, keyword_init: true) do
      # id is used for sorting on the front end
      def id
        "#{sortable_date}.#{enrollment.id}.#{topic}"
      end

      def sortable_date
        (due_date || (Date.current + 100.years)).iso8601
      end
    end
  end
end
