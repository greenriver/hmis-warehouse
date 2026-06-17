###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateAnalyticsCasReferralContacts < ActiveRecord::Migration[7.1]
  def change
    replace_view 'analytics.cas_referral_contacts', version: 2, revert_to_version: 1
  end
end
