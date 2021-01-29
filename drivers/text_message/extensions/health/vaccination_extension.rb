###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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
        # where we haven't already setup follow-up messages
        with_phone.where.not(id: joins(:text_messages).select(:id)).find_each do |vaccination|
          topic = TextMessage::Topic.where(title: 'COVID-19 Second Dose Reminders').first_or_create do |new_topic|
            new_topic.send_hour = 9
          end
          subscriber = topic.topic_subscribers.
            where(
              first_name: vaccination.first_name,
              last_name: vaccination.last_name,
              phone_number: follow_up_cell_phone.tr('^0-9', ''),
            ).first_or_create do |subs|
            subs.subscribed_at = Time.current
            subs.preferred_language = clean_preferred_language
          end

          # Initial reminder
          subscriber.messages.where(
            topic: topic,
            send_on_or_after: follow_up_date - 1.weeks,
          ).first_or_create do |message|
            message.content = initial_reminder_content
            message.source = self
          end

          # Second reminder
          subscriber.messages.where(
            topic: topic,
            send_on_or_after: follow_up_date - 1.days,
          ).first_or_create do |message|
            message.content = second_reminder_content
            message.source = self
          end
        end
      end

      private def clean_preferred_language
        # TODO: adjust based on real data
        preferred_language
      end

      private def remove_text_messages
        text_messages.unsent.destroy_all
      end

      private def initial_reminder_content
        case preferred_language.to_s
        when 'es'
          "RECORDATORIO: Su segunda dosis de la vacuna COVID-19 vence el #{follow_up_date.strftime('%m/%d/%Y')}. Haga un seguimiento en el lugar donde recibió su primera vacuna para su segunda dosis."
        else
          "REMINDER: Your second dose of the COVID-19 vaccine is due on #{follow_up_date.strftime('%m/%d/%Y')}. Please follow up at the site you received your first vaccine for your second dose."
        end
      end

      private def second_reminder_content
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
