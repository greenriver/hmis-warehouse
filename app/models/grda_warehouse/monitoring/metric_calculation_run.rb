###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Monitoring
  class MetricCalculationRun < GrdaWarehouseBase
    validates :entity_type, presence: true
    validates :calculation_date, presence: true
    validates :started_at, presence: true
    validates :status, inclusion: { in: ['running', 'completed', 'failed'] }

    scope :for_entity_type, ->(type) { where(entity_type: type) }
    scope :recent, -> { where(calculation_date: 30.days.ago.to_date..).order(calculation_date: :desc) }
    scope :failed, -> { where(status: 'failed') }
    scope :completed, -> { where(status: 'completed') }
  end
end
