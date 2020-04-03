###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class HeController < HealthController
    include ContactTracingController
    def search
      @show_ssn = GrdaWarehouse::Config.get(:show_partial_ssn_in_window_search_results) || can_view_full_ssn?
      @searcher = Health::Tracing::Search.new(query: params[:q])
      @results = @searcher.results
    end
  end
end
