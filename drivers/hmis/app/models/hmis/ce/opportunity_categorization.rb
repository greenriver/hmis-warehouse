###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

#
# DEPRECATED
#
# join table between opportunities and categories
module Hmis::Ce
  class OpportunityCategorization < GrdaWarehouseBase
    belongs_to :opportunity, class_name: 'Hmis::Ce::Opportunity'
    belongs_to :category, class_name: 'Hmis::Ce::OpportunityCategory'
  end
end
