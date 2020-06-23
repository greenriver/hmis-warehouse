###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class CeAssessmentsController < ApplicationController
    include WarehouseReportAuthorization

    def index
      @column = sort_options.map { |i| i[:column] }.detect { |c| c == params[:column] } || 'assessment_date'
      @direction = ['asc', 'desc'].detect { |c| c == params[:direction] } || 'desc'

      @clients = GrdaWarehouse::Hud::Client.
        preload(:ce_assessments).
        joins(:ce_assessments).
        merge(GrdaWarehouse::CoordinatedEntryAssessment::Base.active.visible_by?(current_user)).
        viewable_by(current_user)

      @clients = sort_clients(@clients, @column, @direction)

      respond_to do |format|
        format.html do
          @clients = @clients.page(params[:page].to_i).per(25)
        end
        format.xlsx do
          headers['Content-Disposition'] = 'attachment; filename=ce_assessments.xlsx'
        end
      end
    end

    private def sort_clients(clients, column, direction)
      case column
      when 'assessment_date'
        clients.order(created_at: direction)
      when 'last_name'
        clients.order(last_name: direction, first_name: direction)
      else
        clients
      end
    end

    private def sort_options
      [
        {
          column: 'assessment_date',
          direction: :desc,
          title: 'Most Recent Assessments',
        },
        {
          column: 'assessment_date',
          direction: :asc,
          title: 'Least Recent Assessments',
        },
        {
          column: 'last_name',
          direction: :asc,
          title: 'Last name A-Z',
        },
        {
          column: 'last_name',
          direction: :desc,
          title: 'Last name Z-A',
        },
      ]
    end
    helper_method :sort_options

    private def detail_columns
      @detail_columns ||= {
        'WarehouseID' => [:client, :id],
        'Client Name' => [:client, :name],
        'DOB' => [:client, :DOB],

        'Started At' => [:assessment, :created_at],
        'Submitted At' => [:assessment, :submitted_at],
        'Assessment Score' => [:assessment, :score],
        'Vulnerability Score' => [:assessment, :vulnerability_score],
        'Priority Score' => [:assessment, :priority_score],

        'Assessor' => [:assessor, :name],

        'Current Location' => [:assessment, :location],
        'Military Duty' => [:assessment, :military_duty],
        'Under 25' => [:assessment, :under_25],
        'Over 60' => [:assessment, :over_60],
        'LGBTQ' => [:assessment, :lgbtq],
        'Children Under 18' => [:assessment, :children_under_18],
        'Fleeing DV' => [:assessment, :fleeing_dv],
        'Living Outdoors' => [:assessment, :living_outdoors],
        'Urgent Health Issue' => [:assessment, :urgent_health_issue],

        _('Location Option 1') => [:assessment, :location_option_1],
        _('Location Option 2') => [:assessment, :location_option_2],
        _('Location Option 3') => [:assessment, :location_option_3],
        _('Location Option 4') => [:assessment, :location_option_4],
        'Other Location' => [:assessment, :location_option_other],
        'Unwanted Location' => [:assessment, :location_option_no],
        'No Location Preference' => [:assessment, :location_no_preference],

        'Homelessness Score' => [:assessment, :homelessness],
        'Substance Use Score' => [:assessment, :substance_use],
        'Mental Health Score' => [:assessment, :mental_health],
        'Health Care Score' => [:assessment, :health_care],
        'Legal Issues Score' => [:assessment, :legal_issues],
        'Income Score' => [:assessment, :income],
        'Work Score' => [:assessment, :work],
        'Independent Living Score' => [:assessment, :independent_living],
        'Community Involvement Score' => [:assessment, :community_involvement],
        'Survival Skills Score' => [:assessment, :survival_skills],

        'Barrier: No Rental History' => [:assessment, :barrier_no_rental_history],
        'Barrier: No Income' => [:assessment, :barrier_no_income],
        'Barrier: Poor Credit' => [:assessment, :barrier_poor_credit],
        'Barrier: Eviction History' => [:assessment, :barrier_eviction_history],
        'Barrier: Eviction from Public Housing' => [:assessment, :barrier_eviction_from_public_housing],
        'Barrier: Need 3+ Bedrooms' => [:assessment, :barrier_bedrooms_3],
        'Barrier: Service Animal' => [:assessment, :barrier_service_animal],
        'Barrier: CORI Issues' => [:assessment, :barrier_cori_issues],
        'Barrier: Registered Sex Offender' => [:assessment, :barrier_registered_sex_offender],
        'Other Barriers' => [:assessment, :barrier_other],

        'Prefer: Studio or SRO' => [:assessment, :preferences_studio],
        'Prefer: Roommate' => [:assessment, :preferences_roomate],
        'Prefer: Pets Allowed' => [:assessment, :preferences_pets],
        'Prefer: Handicap Accessible' => [:assessment, :preferences_accessible],
        'Prefer: Quiet Neighborhood' => [:assessment, :preferences_quiet],
        'Prefer: Near Public Transportation' => [:assessment, :preferences_public_transport],
        'Prefer: Near Outdoor Spaces (Parks, Trails, Playgrounds)' => [:assessment, :preferences_parks],
        'Other Preferences' => [:assessment, :preferences_other],

        'Assessor Rating' => [:assessment, :assessor_rating],
        'Client Email Address' => [:assessment, :client_email],

        '6+ Months Homeless' => [:assessment, :homeless_six_months],
        '>3 Hospitalizations/ER Visits' => [:assessment, :mortality_hospitilization_3],
        '>3 ER Visits' => [:assessment, :mortality_emergency_room_3],
        'Age 60+' => [:assessment, :mortality_over_60],
        'Cirrhosis' => [:assessment, :mortality_cirrhosis],
        'Renal Disease' => [:assessment, :mortality_renal_disease],
        'Frostbite' => [:assessment, :mortality_frostbite],
        'HIV/AIDS' => [:assessment, :mortality_hiv],
        'Tri-morbidity' => [:assessment, :mortality_tri_morbid],

        'Lack of Shelter Access' => [:assessment, :lacks_access_to_shelter],
        'Potential of Victimization' => [:assessment, :high_potential_for_vicitimization],
        'Danger of Harm' => [:assessment, :danger_of_harm],
        'Acute Medical Condition' => [:assessment, :acute_medical_condition],
        'Acute Psychiatric Condition' => [:assessment, :acute_psychiatric_condition],
        'Acute Substance Abuse' => [:assessment, :acute_substance_abuse],
      }.freeze
    end
    helper_method :detail_columns

    private def report_params
      params.permit(
        :direction,
        :column,
      )
    end
    helper_method :report_params
  end
end
