###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ClientAlert < Hmis::HmisBase
  acts_as_paranoid

  has_paper_trail(
    meta: {
      client_id: ->(r) { r.client&.id },
    },
  )

  HIGH = 'high'.freeze
  MEDIUM = 'medium'.freeze
  LOW = 'low'.freeze
  PRIORITY_LEVELS = [HIGH, MEDIUM, LOW].freeze

  belongs_to :created_by, class_name: 'Hmis::User'
  belongs_to :client, class_name: 'Hmis::Hud::Client'
  attribute :priority, default: LOW
  validates :priority, inclusion: {
    in: PRIORITY_LEVELS,
    message: '%{value} is not a valid priority level',
  }, allow_nil: true # allow nil here because there is a default value of 'low'

  scope :active, -> do
    where(arel_table[:expiration_date].eq(nil).or(arel_table[:expiration_date].gt(Time.current)))
  end
end
