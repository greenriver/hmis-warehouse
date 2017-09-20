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
      @cost_table = @view_model.cost_table
      @km_table = @view_model.key_metrics_table
      @km_rows = [
        [@km_table.patient, 'ho-compare__current-patient'], 
        [@km_table.sdh, 'ho-compare__pilot-average'], 
        [@km_table.variance, 'ho-compare__variance']
      ]
      
      render layout: !request.xhr?      
    end
    
  end
end