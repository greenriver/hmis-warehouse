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
      return if sent_at.present?

      phone_number = topic_subscriber.phone_number
      return unless phone_number.present?

      update(sent_at: Time.current, sent_to: phone_number)
      source&.mark_sent

      sns = Aws::SNS::Client.new
      sns.publish(phone_number: phone_number, message: content)
    end
  end
end
