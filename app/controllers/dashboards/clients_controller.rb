module Dashboards
  class ClientsController < BaseController
    include ArelHelper

    CACHE_EXPIRY = if Rails.env.production? then 8.hours else 2.minutes end 
    before_action :require_can_view_censuses!
    
    def active
      _active(cache_key_prefix: 'active-client')
      render layout: !request.xhr?
    end

    def housed
      all_exits_key = 'housed-client-all-exits'
      all_exits_instance_key = 'housed-client-instance-all-exits'
      _housed(all_exits_key: all_exits_key, all_exits_instance_key: all_exits_instance_key)
      render layout: !request.xhr?
    end

    def entered
      _entered(cache_key_prefix: 'entered-all-clients')
            
      render layout: !request.xhr?
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end
  end
end