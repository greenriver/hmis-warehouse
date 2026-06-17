###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  module Scoring
    class CalculationLog < ::GrdaWarehouseBase
      self.table_name = 'hmis_scoring_calculation_logs'

      belongs_to :owner, polymorphic: true
      belongs_to :user, class_name: 'Hmis::User'

      validates :namespace, :final_score, :calculation_details, presence: true
    end
  end
end
