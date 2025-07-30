###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module AcHmis
  module Scoring
    class Algorithm < ::GrdaWarehouseBase
      self.table_name = 'hmis_scoring_algorithms'

      has_many :scoring_rules, class_name: 'AcHmis::Scoring::Rule', foreign_key: :hmis_scoring_algorithm_id, dependent: :destroy
      has_many :algorithm_thresholds, class_name: 'AcHmis::Scoring::Threshold', foreign_key: :hmis_scoring_algorithm_id, dependent: :destroy

      validates :name, :namespace, presence: true
      validates :name, uniqueness: true
    end
  end
end
