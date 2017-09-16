module Window::Health
  class PatientController < ApplicationController
    before_action :require_can_edit_client_health!
    before_action :set_client, only: [:index]
    before_action :set_patient, only: [:index]
    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator
    
    
    def index
      @patient_summary = load_patient_summary
      render layout: !request.xhr?      
    end

    protected

    def load_patient_summary
      result = {details: [], demographics: []}
      if @patient.present?
        if @patient.claims_roster.present?
          team = @patient.claims_roster.epic_team
          disability_flag = @patient.claims_roster.disability_flag ? 'Y' : 'N'
        else
          team = 'Unknown'
          disability_flag = 'Unknown'
        end
        result[:details] = [
          ['SSN', @patient.ssn],
          ['Medicaid ID', @patient.medicaid_id],
          ['Primary Care Physician', @patient.primary_care_physician],
          ['Team', team]
        ]
        result[:demographics].push([
          ['Age', @patient.client.age], 
          ['Gender', @patient.gender],
          ['Disability Flag', disability_flag],  
        ])
        result[:demographics].push([
          ['DOB', @patient.birthdate],
          ['Race / Ethnicity', "#{@patient.race} / #{@patient.ethnicity}"],
          ['Veteran Status', @patient.veteran_status] 
        ])
      end
      result
    end
  end
end