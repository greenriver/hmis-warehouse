###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# A referral of an individual client to an opportunity
module Hmis::Ce
  class CustomReferralStatus < GrdaWarehouseBase
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

    validates :key, presence: true
    validate :no_collision_with_default_status

    scope :viewable_by, ->(user) do
      where(data_source_id: user.hmis_data_source_id)
    end

    private

    def no_collision_with_default_status
      return if key.blank?

      state_machine_statuses = Hmis::Ce::Referral.state_machine_states.map(&:to_s)
      return unless state_machine_statuses.include?(key)

      errors.add(:key, "cannot be one of the default (state machine) statuses: #{state_machine_statuses.join(', ')}")
    end
  end
end
