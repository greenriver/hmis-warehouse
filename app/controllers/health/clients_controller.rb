module Health
  class ClientsController < ApplicationController
    before_action :require_can_edit_client_health!
    before_action :set_client, only: [:careplan]
    before_action :set_patient, only: [:careplan]
    include PjaxModalController
    include HealthPatient
    
    def careplan

    end

  end
end