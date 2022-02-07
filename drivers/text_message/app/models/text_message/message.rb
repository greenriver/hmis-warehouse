###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'aws-sdk-sns'
module TextMessage
  class Message < GrdaWarehouseBase
    acts_as_paranoid
    belongs_to :topic
    belongs_to :topic_subscriber, foreign_key: :subscriber_id, optional: true
    belongs_to :source, polymorphic: true, optional: true

    scope :unsent, -> do
      where(sent_at: nil)
    end

    scope :sent, -> do
      where.not(sent_at: nil)
    end

    scope :pending, -> do
      where(arel_table[:send_on_or_after].lteq(Date.current))
    end

    def self.send_pending!
      unsent.pending.joins(topic_subscriber: :topic).
        merge(TextMessage::TopicSubscriber.active.valid_phone).
        merge(TextMessage::Topic.active.send_during(Time.current.hour)).
        find_each(&:send!)
    end

    def send!
      # NOTE: setup of long codes is done in Amazon Pinpoint
      # Long codes have a 1/second send limit
      # Responses: https://docs.aws.amazon.com/pinpoint/latest/userguide/channels-sms-two-way.html
      return if sent_at.present?

      if formatted_phone_number.length != 11
        source&.mark_sent("Phone number undeliverable, no reminder sent #{Time.current}") if source.respond_to?(:mark_sent)
        return
      end

      status = :sent
      new_notification = "Sent at #{Time.current}"
      if opted_out?
        status = :opted_out
        topic_subscriber.mark_as_opted_out
        new_notification = "Client opted-out, no reminder sent #{Time.current}"
      end
      update(sent_at: Time.current, sent_to: formatted_phone_number, delivery_status: status)
      source&.mark_sent(new_notification) if source.respond_to?(:mark_sent)
      return if opted_out?

      # Add a delay for compliance with long-code send restrictions
      sleep(1.1)
      sns_client.publish(phone_number: formatted_phone_number, message: content)
    end

    # bundle exec rails runner 'TextMessage::Message.new.test!("1231231234")'
    def test!(phone_number)
      @formatted_phone_number = "1#{phone_number}"
      if opted_out?
        puts 'opted out!'
      else
        content = "Testing message #{SecureRandom.hex(8)}"
        result = sns_client.publish(phone_number: formatted_phone_number, message: content)
        puts "sent: #{result}"
      end
    end

    private def sns_client
      @sns_client ||= Aws::SNS::Client.new
    end

    private def opted_out?
      @opted_out ||= sns_client.check_if_phone_number_is_opted_out(phone_number: formatted_phone_number).is_opted_out
    end

    private def formatted_phone_number
      @formatted_phone_number ||= "1#{topic_subscriber.phone_number}"
    end
  end
end
