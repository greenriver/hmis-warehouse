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
          'Total Stayer Households' => stayers_hoh_count,
          'Stayer Adults' => stayers_adult_count,
          'Stayer Children' => stayers_child_count,
          'Total Leaver Households' => leavers_hoh_count,
          'Leaver Adults' => leavers_adult_count,
          'Leaver Children' => leavers_child_count,
        }
      end
    end

    private def stayers_hoh_count
      filter_for_stayers(hoh_scope).select(:client_id).distinct.count
    end

    private def stayers_adult_count
      filter_for_stayers(filter_for_adults(hoh_scope)).select(:client_id).distinct.count
    end

    private def stayers_child_count
      filter_for_stayers(filter_for_children(hoh_scope)).select(:client_id).distinct.count
    end

    private def leavers_hoh_count
      filter_for_leavers(hoh_scope).select(:client_id).distinct.count
    end

    private def leavers_adult_count
      filter_for_leavers(filter_for_adults(hoh_scope)).select(:client_id).distinct.count
    end

    private def leavers_child_count
      filter_for_leavers(filter_for_children(hoh_scope)).select(:client_id).distinct.count
    end
  end
end
