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
      @patient_summary = load_patient_summary
      @patient_cost = load_patient_cost
      @SDH_cost = load_SDH_cost
      @variance_cost = load_variance_cost

      @patient_key_metrics = load_patient_key_metrics
      @SDH_key_metrics = load_SDH_key_metrics
      @variance_key_metrics = load_variance_key_metrics
      
      render layout: !request.xhr?      
    end

    protected

    def load_variance_cost
      # TODO
      {Total_Cost: '-46%', Months: '-46%', Cost_PMPM: '-46%'}
    end

    def load_variance_key_metrics
      # TODO
      {
        Normalized_Risk: '-54%', 
        ED_Visits: '-9%', 
        IP_Admits: '-100%', 
        Average_Days_to_Readmit: 'N/A'
      }
    end

    def load_patient_key_metrics
      roster = @patient.claims_roster
      result = {}
      if roster
        result = {
          Normalized_Risk: roster.norm_risk_score.round(1) || 'N/A', 
          ED_Visits: roster.ed_visits || 'N/A', 
          IP_Admits: roster.acute_ip_admits || 'N/A', 
          Average_Days_to_Readmit: roster.average_days_to_readmit || 'N/A'
        }
      end
      result
    end

    def load_SDH_key_metrics
      # TODO
      {
        Normalized_Risk: '3.5', 
        ED_Visits: '4', 
        IP_Admits: '1', 
        Average_Days_to_Readmit: '28'
      }
    end

    def load_patient_cost
      result = {Total_Cost: '', Months: '', Cost_PMPM: ''}
      roster = @patient.claims_roster
      if roster && roster.total_ty && roster.mbr_months && roster.mbr_months > 0
        pm_num = (roster.total_ty/roster.mbr_months)
        pm = number_to_currency(pm_num, precision: 0)
      else
        pm = 'N/A'
      end
      if roster
        result = {
          Total_Cost: roster.total_ty ? number_to_currency(roster.total_ty, precision: 0) : 'N/A', 
          Months: roster.mbr_months || 'N/A',
          Cost_PMPM: pm
        }
      end
      result
    end

    def load_SDH_cost
      # TODO
      result = {Total_Cost: '$113,700', Months: '11.5', Cost_PMPM: '$9,920'}
    end

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