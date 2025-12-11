###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddCanViewOutgoingReferralDetailsPermission < ActiveRecord::Migration[7.1]
  def up
    ::Hmis::Role.ensure_permissions_exist
    ::Hmis::Role.reset_column_information
  end

  def down
    remove_column :hmis_roles, :can_view_outgoing_referral_details
  end
end
