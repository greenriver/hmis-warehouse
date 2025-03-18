# frozen_string_literal: true

# Free-form notes a referral
module Hmis::Ce
  class ReferralNote < GrdaWarehouseBase
    belongs_to :referral, class_name: 'Hmis::Ce::Referral'
    belongs_to :user, class_name: 'Hmis::User'
  end
end
