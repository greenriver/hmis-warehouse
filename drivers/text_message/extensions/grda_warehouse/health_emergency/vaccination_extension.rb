module TextMessage::GrdaWarehouse::HealthEmergency
  module VaccinationExtension
    extend ActiveSupport::Concern
    included do
      after_create_commit :add_text_message_subscription

      def add_text_message_subscription
        # Don't queue for imported vaccinations, that will happen
        # via a different mechanism
        return if health_vaccination_id.present?
        return unless follow_up_on.present?
        return unless follow_up_cell_phone.present?

        topic = TextMessage::Topic.where(title: 'COVID-19 Second Dose Reminders').first_or_create
        subscriber = topic.topic_subscribers.
          where(
            first_name: client.FirstName,
            last_name: client.LastName,
            phone_number: follow_up_cell_phone.tr('^0-9', ''),
          ).first_or_create do |sub|
          sub.subscribed_at = Time.current
        end

        # Initial reminder
        subscriber.messages.where(
          topic: topic,
          send_on_or_after: follow_up_on - 1.weeks,
        ).first_or_create do |mes|
          mes.content = initial_reminder_content
        end

        # Second reminder
        subscriber.messages.where(
          topic: topic,
          send_on_or_after: follow_up_on - 1.days,
        ).first_or_create do |mes|
          mes.content = second_reminder_content
        end
      end

      private def initial_reminder_content
        "REMINDER: Your second dose of the COVID-19 vaccine is due on #{follow_up_on.strftime('%m/%d/%Y')}. Please follow up at the site you received your first vaccine for your second dose."
      end

      private def second_reminder_content
        "REMINDER: Your second dose of the COVID-19 vaccine is due on #{follow_up_on.strftime('%m/%d/%Y')}. Please follow up at the site you received your first vaccine for your second dose."
      end
    end
  end
end
