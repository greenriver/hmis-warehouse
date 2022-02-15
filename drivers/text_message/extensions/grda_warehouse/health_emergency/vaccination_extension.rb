###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TextMessage::GrdaWarehouse::HealthEmergency
  module VaccinationExtension
    extend ActiveSupport::Concern
    included do
      has_many :text_messages, class_name: 'TextMessage::Message', as: :source

      after_create_commit :add_text_message_subscription
      after_destroy :remove_text_messages

      def mark_sent(new_notification)
        new_status = notification_status.presence || ''
        new_status << "\n" unless notification_status.blank?
        new_status << new_notification
        update(
          follow_up_notification_sent_at: Time.current,
          notification_status: new_status,
        )
      end

      def add_text_message_subscription
        # Remove any existing unsent messages if the client is now considered vaccinated
        remove_related_text_messages if status == GrdaWarehouse::HealthEmergency::Vaccination::VACCINATED
        return unless GrdaWarehouse::Config.get(:send_sms_for_covid_reminders)
        # Don't queue for imported vaccinations, that will happen
        # via a different mechanism
        return if health_vaccination_id.present?
        return unless follow_up_on.present?
        return unless follow_up_cell_phone.present?

        # Initial reminder
        topic_subscriber.messages.where(
          topic: topic,
          send_on_or_after: follow_up_on - 1.weeks,
        ).first_or_create do |message|
          message.content = initial_reminder_content
          message.source = self
        end

        # Second reminder
        topic_subscriber.messages.where(
          topic: topic,
          send_on_or_after: follow_up_on - 1.days,
        ).first_or_create do |message|
          message.content = second_reminder_content
          message.source = self
        end
      end

      private def topic
        @topic ||= TextMessage::Topic.where(title: 'COVID-19 Second Dose Reminders').first_or_create do |topic|
          topic.send_hour = 9
        end
      end

      private def topic_subscriber
        @topic_subscriber ||= begin
          subscriber = topic.topic_subscribers.where(client_id: client.id).first_or_initialize
          subscriber.update(
            first_name: client.FirstName,
            last_name: client.LastName,
            phone_number: follow_up_cell_phone.tr('^0-9', ''),
            subscribed_at: Time.current,
            preferred_language: preferred_language,
          )
          subscriber
        end
      end

      private def remove_text_messages
        text_messages.unsent.destroy_all
      end

      private def remove_related_text_messages
        topic_subscriber.messages.destroy_all
      end

      private def initial_reminder_content
        case preferred_language.to_s
        when 'es'
          "Recordatorio: La fecha para su segunda dosis de la vacuna para el Covid-19 se cumple el #{follow_up_on.strftime('%m/%d/%Y')}. Por favor comuniquese con el sitio donde recibio la primera vacuna para recibir la segunda dosis."
        else
          "REMINDER: Your second dose of the COVID-19 vaccine is due on #{follow_up_on.strftime('%m/%d/%Y')}. Please follow up at the site you received your first vaccine for your second dose."
        end
      end

      private def second_reminder_content
        case preferred_language.to_s
        when 'es'
          "Recordatorio: La fecha para su segunda dosis de la vacuna para el Covid-19 se cumple el #{follow_up_on.strftime('%m/%d/%Y')}. Por favor comuniquese con el sitio donde recibio la primera vacuna para recibir la segunda dosis."
        else
          "REMINDER: Your second dose of the COVID-19 vaccine is due on #{follow_up_on.strftime('%m/%d/%Y')}. Please follow up at the site you received your first vaccine for your second dose."
        end
      end
    end
  end
end
