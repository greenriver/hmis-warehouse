# Free-form notes a referral
module Hmis::Ce
  class ReferralNote < GrdaWarehouseBase
    belongs_to :referral, class_name: 'Hmis::Ce::Referral'
  end
end
