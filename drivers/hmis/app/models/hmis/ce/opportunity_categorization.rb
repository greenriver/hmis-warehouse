# frozen_string_literal: true

# join table between opportunities and categories
module Hmis::Ce
  class OpportunityCategorization < GrdaWarehouseBase
    belongs_to :opportunity, class_name: 'Hmis::Ce::Opportunity'
    belongs_to :category, class_name: 'Hmis::Ce::OpportunityCategory'
  end
end
