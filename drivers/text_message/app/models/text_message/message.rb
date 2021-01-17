###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'aws-sdk-sns'
module TextMessage
  class Message < GrdaWarehouseBase
    acts_as_paranoid
    belongs_to :topic
    belongs_to :topic_subscriber, foreign_key: :subscriber_id
    belongs_to :source, polymorphic: true, optional: true

    scope :unsent, -> do
      where(sent_at: nil)
    end

    scope :sent, -> do
      where.not(sent_at: nil)
    end

    def send!
      # NOTE: setup of long codes is done in Amazon Pinpoint
      # Long codes have a 1/second send limit
      # Responses: https://docs.aws.amazon.com/pinpoint/latest/userguide/channels-sms-two-way.html
      return if sent_at.present?

      phone_number = topic_subscriber.phone_number
      return unless phone_number.present? && phone_number.length == 10

      phone_number = "1#{phone_number}"
      update(sent_at: Time.current, sent_to: phone_number)
      source&.mark_sent

      # Add a delay for compliance with long-code send restrictions
      sleep(1.1)
      sns = Aws::SNS::Client.new
      sns.publish(phone_number: phone_number, message: content)
    end
  end
end
