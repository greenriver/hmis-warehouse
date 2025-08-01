###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module AcHmis
  module Scoring
    class CalculationLog < ::GrdaWarehouseBase
      self.table_name = 'hmis_scoring_calculation_logs'

      belongs_to :owner, polymorphic: true
      belongs_to :user

      validates :namespace, :final_score, :calculation_details, presence: true
    end
  end
end
