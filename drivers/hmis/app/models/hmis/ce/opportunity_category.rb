# Categories are used to group similar opportunities and enforce mutual exclusivity.
# When a client has an active referral to an opportunity, they are not eligible for other
# opportunities in any of the same categories. This prevents clients from being referred
# to multiple opportunities that serve the same purpose (e.g., multiple housing programs)
# simultaneously.
module Hmis::Ce
  class OpportunityCategory < GrdaWarehouseBase
    has_many :categorizations, class_name: 'Hmis::Ce::OpportunityCategorization', foreign_key: :category_id
    has_many :opportunities, through: :categorizations
  end
end
