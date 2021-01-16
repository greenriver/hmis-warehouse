###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TextMessage
  class TopicSubscriber < GrdaWarehouseBase
    belongs_to :topic
    has_many :messages

    scope :active, -> do
      where(unsubscribed_at: nil)
    end
  end
end
