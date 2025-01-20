# categorizes opportunities
module Hmis::Ce
  class OpportunityCategory < GrdaWarehouseBase
    has_many :categorizations, class_name: 'Hmis::Ce::OpportunityCategorization', foreign_key: :category_id
    has_many :opportunities, through: :categorizations
  end
end
