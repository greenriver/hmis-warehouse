###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Api::Health::Claims
  class TopConditionsController < BaseController
    def load_data
      total_paid_baseline = source.sum(:baseline_paid)
      total_paid_implementation = source.sum(:implementation_paid)
      baseline_paid_by_provider_name = source.group(:description).
        sum(:baseline_paid)

      @data = source.group(:description).
        sum(:implementation_paid).
        sort_by { |_k, v| v }.
        reverse.
        first(5).
        map do |description, sum_paid|
        {
          description: description,
          sdh_pct: baseline_paid_by_provider_name[description] / total_paid_baseline,
          indiv_pct: sum_paid / total_paid_implementation,
        }
      end
    end

    def source
      ::Health::Claims::TopConditions
    end
  end
end
