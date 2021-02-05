###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TextMessage
  class TopicSubscriber < GrdaWarehouseBase
    acts_as_paranoid
    belongs_to :topic
    has_many :messages, foreign_key: :subscriber_id

    scope :active, -> do
      where(unsubscribed_at: nil)
    end

    def name
      "#{first_name} #{last_name}"
    end

    def mark_as_opted_out
      self.unsubscribed_at ||= Time.current
      save
    end
  end
end
