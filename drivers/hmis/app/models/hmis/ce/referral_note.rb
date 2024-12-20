# Referral Steps represent formal stages in a structured workflow:
#
# * They map to corresponding steps in the workflow definition
# * Have a clear lifecycle (pending → in_progress → completed)
# * Track who is responsible (assigned_to)
# * Control progression through the workflow via transitions and dependencies
# * Support triggers for actions such notifications or enrollment
#
module Hmis::Ce
  class ReferralNote < GrdaWarehouseBase
    belongs_to :referral, class_name: 'Hmis::Ce::Referral'
  end
end
