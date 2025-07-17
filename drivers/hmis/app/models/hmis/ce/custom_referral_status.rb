###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# This model represents the custom, or user-facing, referral status. Referrals have a foreign key to this table.
# CustomReferralStatus is distinct from the referral's state-machine status. Here are some notes on the differences:
#
# State machine status:
# - examples: initialized, in_progress, accepted, rejected.
# - defined statically in the code on the Referral model
# - stored in the `status` column on the referral table
# - used internally to track the referral's logical state as it progresses through the workflow
#
# CustomReferralStatus:
# - examples: denied_pending
# - defined dynamically in the database, per data source. Can be customized per installation
# - stored as a foreign key on the referral table (custom_referral_status_id)
# - used for displaying the referral's current status to the user in the frontend, and providing a dropdown to filter referrals by status
# - all State Machine statuses should be included in the CustomReferralStatus table in order for filtering to work correctly!
#   See HmisUtil::CeBuilder.create_state_machine_custom_statuses.

module Hmis::Ce
  class CustomReferralStatus < GrdaWarehouseBase
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

    scope :viewable_by, ->(user) do
      where(data_source_id: user.hmis_data_source_id)
    end
  end
end
