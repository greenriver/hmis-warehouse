module Hmis
  module Reminders
    Reminder = Struct.new(:id, :topic, :enrollment_id, :due_date, :description, keyword_init: true)
  end
end
