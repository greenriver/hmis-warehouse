###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TextMessage::Health
  module VaccinationExtension
    extend ActiveSupport::Concern
    included do
      has_many :text_messages, class_name: 'TextMessage::Message', as: :source

      after_destroy :remove_text_messages

      def self.queue_sms
        return unless GrdaWarehouse::Config.get(:send_sms_for_covid_reminders)

        # Find any vaccinations with contact information
        # where we haven't already setup follow-up messages.
        # Don't create the reminder if the date has passed
        # NOTE: text messages exist in a different database
        existing_text_message_vaccination_ids = TextMessage::Message.where(source_type: 'Health::Vaccination').pluck(:source_id)
        with_phone.where.not(id: existing_text_message_vaccination_ids).find_each do |vaccination|
          topic = TextMessage::Topic.where(title: 'COVID-19 Second Dose Reminders').first_or_create do |new_topic|
            new_topic.send_hour = 9
          end
          # Don't bother if we have already had two vaccinations
          next unless vaccination.follow_up_date

          subscriber = topic.topic_subscribers.
            where(
              first_name: vaccination.first_name,
              last_name: vaccination.last_name,
              phone_number: vaccination.follow_up_cell_phone&.tr('^0-9', ''),
            ).first_or_create do |subs|
            subs.subscribed_at = Time.current
            subs.preferred_language = vaccination.clean_preferred_language
          end

          # Second reminder
          reminder_date = vaccination.follow_up_date - 1.days
          next if reminder_date.to_date <= Date.current

          subscriber.messages.where(
            topic: topic,
            send_on_or_after: reminder_date,
          ).first_or_create do |message|
            message.content = vaccination.second_reminder_content
            message.source = vaccination
          end

          # Initial reminder
          reminder_date = vaccination.follow_up_date - 1.weeks
          next if reminder_date.to_date <= Date.current

          subscriber.messages.where(
            topic: topic,
            send_on_or_after: reminder_date,
          ).first_or_create do |message|
            message.content = vaccination.initial_reminder_content
            message.source = vaccination
          end
        end
      end

      def clean_preferred_language
        case preferred_language
        when 'Spanish'
          'es'
        else
          'en'
        end
      end

      private def remove_text_messages
        text_messages.unsent.destroy_all
      end

      def initial_reminder_content
        case preferred_language.to_s
        when 'es'
          "RECORDATORIO: Su segunda dosis de la vacuna COVID-19 vence el #{follow_up_date.strftime('%m/%d/%Y')}. Haga un seguimiento en el lugar donde recibió su primera vacuna para su segunda dosis."
        else
          "REMINDER: Your second dose of the COVID-19 vaccine is due on #{follow_up_date.strftime('%m/%d/%Y')}. Please follow up at the site you received your first vaccine for your second dose."
        end
      end

      def second_reminder_content
        case preferred_language.to_s
        when 'es'
          "RECORDATORIO: Su segunda dosis de la vacuna COVID-19 vence el #{follow_up_date.strftime('%m/%d/%Y')}. Haga un seguimiento en el lugar donde recibió su primera vacuna para su segunda dosis."
        else
          "REMINDER: Your second dose of the COVID-19 vaccine is due on #{follow_up_date.strftime('%m/%d/%Y')}. Please follow up at the site you received your first vaccine for your second dose."
        end
      end
    end
  end
end
