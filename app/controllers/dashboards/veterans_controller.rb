module Dashboards
  class VeteransController < BaseController
    include ArelHelper

    CACHE_EXPIRY = if Rails.env.production? then 8.hours else 2.minutes end 
    before_action :require_can_view_censuses!
    
    def active
      _active(cache_key_prefix: 'active-vet')
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
      _entered(cache_key_prefix: 'entered-vet')
            
      render layout: !request.xhr?
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination.veteran
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end
  end
end