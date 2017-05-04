module Dashboards
  class VeteransController < BaseController
    include ArelHelper

    CACHE_EXPIRY = if Rails.env.production? then 8.hours else 2.minutes end 
    before_action :require_can_view_censuses!
    
    def active
      client_cache_key = 'active-vet-clients'
      enrollment_cache_key = 'active-vet-enrollments'
      client_count_key = 'active-vet-client-count'
      _active(client_cache_key: client_cache_key, enrollment_cache_key: enrollment_cache_key, client_count_key: client_count_key)
      render layout: !request.xhr?
    end

    def housed
      all_exits_key = 'housed-veteran-all-exits'
      all_exits_instance_key = 'housed-veterans-instance-all-exits'
      _housed(
        all_exits_key: all_exits_key, 
        all_exits_instance_key: all_exits_instance_key,
        start_date: '2014-07-01'.to_date
      )
      render layout: !request.xhr?
    end

    def entered
      enrollments_by_client_key = 'entered-vet-enrollments_by_client'
      seen_in_past_month_key = 'entered-vet-seen_in_past_month'
      _entered(enrollments_by_client_key: enrollments_by_client_key, seen_in_past_month_key: seen_in_past_month_key)
            
      render layout: !request.xhr?
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination.veteran
    end
  end
end