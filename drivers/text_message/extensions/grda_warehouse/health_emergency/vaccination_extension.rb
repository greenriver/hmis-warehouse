module TextMessage::GrdaWarehouse::HealthEmergency
  module VaccinationExtension
    extend ActiveSupport::Concern
    included do
      has_many :text_messages, class_name: 'TextMessage::Message', as: :source

      after_create_commit :add_text_message_subscription

      def mark_sent
        update(follow_up_notification_sent_at: Time.current)
      end

      def add_text_message_subscription
        return unless GrdaWarehouse::Config.get(:send_sms_for_covid_reminders)
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
          ).first_or_create do |subs|
          subs.subscribed_at = Time.current
          subs.preferred_language = preferred_language
        end

        # Initial reminder
        subscriber.messages.where(
          topic: topic,
          send_on_or_after: follow_up_on - 1.weeks,
        ).first_or_create do |message|
          message.content = initial_reminder_content
          message.source = self
        end

        # Second reminder
        subscriber.messages.where(
          topic: topic,
          send_on_or_after: follow_up_on - 1.days,
        ).first_or_create do |message|
          message.content = second_reminder_content
          message.source = self
        end
      end

      private def initial_reminder_content
        case preferred_language.to_s
        when 'es'
          "RECORDATORIO: Su segunda dosis de la vacuna COVID-19 vence el #{follow_up_on.strftime('%m/%d/%Y')}. Haga un seguimiento en el lugar donde recibió su primera vacuna para su segunda dosis."
        else
          "REMINDER: Your second dose of the COVID-19 vaccine is due on #{follow_up_on.strftime('%m/%d/%Y')}. Please follow up at the site you received your first vaccine for your second dose."
        end
      end

      private def second_reminder_content
        case preferred_language.to_s
        when 'es'
          "RECORDATORIO: Su segunda dosis de la vacuna COVID-19 vence el #{follow_up_on.strftime('%m/%d/%Y')}. Haga un seguimiento en el lugar donde recibió su primera vacuna para su segunda dosis."
        else
          "REMINDER: Your second dose of the COVID-19 vaccine is due on #{follow_up_on.strftime('%m/%d/%Y')}. Please follow up at the site you received your first vaccine for your second dose."
        end
      end
    end
  end
end
