module Window::Health
  class PatientController < ApplicationController
    before_action :require_can_edit_client_health!
    before_action :set_client, only: [:index]
    before_action :set_patient, only: [:index]
    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator
    include ActionView::Helpers::NumberHelper
    
    helper HealthOverviewHelper

    def index
      @rosters = ::Health::Claims::Roster.all

      @view_model = ::Health::Claims::ViewModel.new(@patient, @rosters)
      @patient_summary = @view_model.patient_summary
      
      @cost = @view_model.cost_table
      @patient_cost = @cost[:patient]
      @SDH_cost = @cost[:sdh_cost]
      @variance_cost = @cost[:variance]

      @key_metrics = @view_model.key_metrics_table
      @patient_key_metrics = @key_metrics[:patient]
      @SDH_key_metrics = @key_metrics[:sdh_cost]
      @variance_key_metrics = @key_metrics[:variance]
      
      render layout: !request.xhr?      
    end
    
  end
end