###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TextMessage
  class Topic < GrdaWarehouseBase
    acts_as_paranoid
    has_many :messages
    has_many :topic_subscribers

    scope :active, -> do
      where(active_topic: true)
    end

    scope :send_during, ->(hour) do
      where(arel_table[:send_hour].eq(nil).or(arel_table[:send_hour].eq(hour)))
    end

    def send_batch
      return unless active_topic

      messages.unsent.joins(:topic_subscribers).
        merge(TopicSubscribers.active).
        preload(:topic_subscribers).
        find_each(&:send!)
    end
  end
end
