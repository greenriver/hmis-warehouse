###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Api::Health::Claims
  class TopProvidersController < BaseController
    def load_data
      total_paid_baseline = source.sum(:baseline_paid)
      total_paid_implementation = source.sum(:implementation_paid)
      baseline_paid_by_provider_name = source.group(:provider_name).
        sum(:baseline_paid)

      @data = source.group(:provider_name).
        sum(:implementation_paid).
        sort_by { |_k, v| v }.
        reverse.
        first(5).
        map do |provider_name, sum_paid|
        {
          provider_name: provider_name,
          sdh_pct: baseline_paid_by_provider_name[provider_name] / total_paid_baseline,
          indiv_pct: sum_paid / total_paid_implementation,
        }
      end
    end

    def source
      ::Health::Claims::TopProviders
    end
  end
end
