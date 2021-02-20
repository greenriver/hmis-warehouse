###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  IncomeBenefitsReport::StayerHouseholds
  extend ActiveSupport::Concern
  included do
    def stayer_households_data
      @stayer_households_data ||= Rails.cache.fetch(cache_key_for_section('stayer_households'), expires_in: expiration_length) do
        {
          'Households with Earned Income at Last Update' => {
            count: 0,
            percent: 0,
          },
          'Households with Non-Employment Income at Last Update' => {
            count: 0,
            percent: 0,
          },
          'Households with Total Income (Earned and Non-Employment) at Last Update' => {
            count: 0,
            percent: 0,
          },
          'Total Adults with Entries' => 0,
          'Total Adults with Exits' => 0,
          'Average Income at Entry' => 0,
          'Average Income at Last Update' => 0,
          'Total Adults that Increased Income' => 0,
          'Total Adults that Maintained Income' => 0,
          'Total Adults that Lost Income' => 0,
        }
      end
    end

    # private def stayers_hoh_count
    #   filter_for_stayers(hoh_scope).select(:client_id).distinct.count
    # end

    # private def stayers_adult_count
    #   filter_for_stayers(filter_for_adults(hoh_scope)).select(:client_id).distinct.count
    # end

    # private def stayers_child_count
    #   filter_for_stayers(filter_for_children(hoh_scope)).select(:client_id).distinct.count
    # end

    # private def leavers_hoh_count
    #   filter_for_leavers(hoh_scope).select(:client_id).distinct.count
    # end

    # private def leavers_adult_count
    #   filter_for_leavers(filter_for_adults(hoh_scope)).select(:client_id).distinct.count
    # end

    # private def leavers_child_count
    #   filter_for_leavers(filter_for_children(hoh_scope)).select(:client_id).distinct.count
    # end
  end
end
