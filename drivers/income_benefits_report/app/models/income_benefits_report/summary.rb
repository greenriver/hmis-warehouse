###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  IncomeBenefitsReport::Summary
  extend ActiveSupport::Concern
  included do
    def summary_data
      @summary_data ||= Rails.cache.fetch(cache_key_for_section('summary'), expires_in: expiration_length) do
        {
          'Total Stayer Households' => stayers_hoh.select(:client_id).count,
          'Stayer Adults' => stayers_adult.select(:client_id).count,
          'Stayer Children' => stayers_child.select(:client_id).count,
          'Total Leaver Households' => leavers_hoh.select(:client_id).count,
          'Leaver Adults' => leavers_adult.select(:client_id).count,
          'Leaver Children' => leavers_child.select(:client_id).count,
        }
      end
    end

    private def stayers_hoh
      filter_for_stayers(hoh_scope).distinct
    end

    private def stayers_adult
      filter_for_stayers(filter_for_adults(report_scope)).distinct
    end

    private def stayers_child
      filter_for_stayers(filter_for_children(report_scope)).distinct
    end

    private def leavers_hoh
      filter_for_leavers(hoh_scope).distinct
    end

    private def leavers_adult
      filter_for_leavers(filter_for_adults(report_scope)).distinct
    end

    private def leavers_child
      filter_for_leavers(filter_for_children(report_scope)).distinct
    end
  end
end
