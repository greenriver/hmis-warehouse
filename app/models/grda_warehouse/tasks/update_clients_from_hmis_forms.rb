###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks
  class UpdateClientsFromHmisForms
    include NotifierConfig
    attr_accessor :logger, :send_notifications, :notifier_config
    def initialize(client_ids: [])
      setup_notifier('HMIS Form -> Client Sync')
      self.logger = Rails.logger
      @client_ids = client_ids
    end

    def run!
      # Fail gracefully if there's no ETO API
      return unless GrdaWarehouse::Config.get(:eto_api_available)

      # @notifier.ping('Updating clients from HMIS Forms...') if @send_notifications
      GrdaWarehouse::HmisForm.set_pathways_results
      GrdaWarehouse::HmisForm.covid_19_impact_assessment_results
      update_rrh_assessment_data()
      update_pathways_assessment_data()
      # @notifier.ping('Updated clients from HMIS Forms') if @send_notifications
    end

    def update_rrh_assessment_data
      clients = clients_with_rrh_assessments()
      clients.find_each do |client|
        assessment = most_recent_rrh_assessment(client)
        client.rrh_assessment_score = assessment.rrh_assessment_score
        client.rrh_assessment_collected_at = assessment.collected_at
        client.ssvf_eligible = assessment.veteran_score.present?
        client.rrh_desired = assessment.rrh_desired?
        client.youth_rrh_desired = assessment.youth_rrh_desired?
        client.rrh_assessment_contact_info = assessment.rrh_contact_info

        client.save
      end
    end

    def update_pathways_assessment_data
      clients = clients_with_pathways_assessments()
      clients.find_each do |client|
        assessment = most_recent_pathways_assessment(client)
        monthly_income = if assessment&.income_total_annual&.positive?
          assessment.income_total_annual / 12
        else
          0
        end
        client.rrh_assessment_collected_at = assessment.assessment_completed_on
        client.rrh_assessment_score = assessment.assessment_score
        client.rrh_desired = assessment.rrh_desired
        client.youth_rrh_desired = assessment.youth_rrh_desired
        client.income_maximization_assistance_requested = assessment.income_maximization_assistance_requested
        client.income_total_monthly = monthly_income
        client.pending_subsidized_housing_placement = assessment.pending_subsidized_housing_placement
        client.pathways_domestic_violence = assessment.domestic_violence
        client.interested_in_set_asides = assessment.interested_in_set_asides
        client.required_number_of_bedrooms = assessment.required_number_of_bedrooms
        client.required_minimum_occupancy = assessment.required_minimum_occupancy
        client.requires_wheelchair_accessibility = assessment.requires_wheelchair_accessibility
        client.requires_elevator_access = assessment.requires_elevator_access
        client.rrh_th_desired = assessment.rrh_th_desired
        client.sro_ok = assessment.sro_ok
        client.pathways_other_accessibility = assessment.other_accessibility
        client.pathways_disabled_housing = assessment.disabled_housing
        client.evicted = assessment.evicted

        client.neighborhood_interests = Cas::Neighborhood.neighborhood_ids_from_names(assessment.neighborhood_interests)

        case assessment.youth_rrh_aggregate
        when 'youth'
          client.youth_rrh_desired = true
        when 'adult'
          client.rrh_desired = true
        when 'both'
          client.youth_rrh_desired = true
          client.rrh_desired = true
        end
        case assessment.dv_rrh_aggregate
        when 'dv'
          client.dv_rrh_desired = true
        when 'non-dv'
          client.rrh_desired = true
        when 'both'
          client.dv_rrh_desired = true
          client.rrh_desired = true
        end

        client.save
      end
    end

    def clients_with_rrh_assessments
      client_scope.joins(:source_hmis_forms).
        merge(GrdaWarehouse::HmisForm.rrh_assessment).distinct
    end

    def clients_with_pathways_assessments
      client_scope.joins(:source_hmis_forms).
        merge(GrdaWarehouse::HmisForm.pathways).distinct
    end

    def client_scope
      if @client_ids.any?
        GrdaWarehouse::Hud::Client.where(id: @client_ids)
      else
        GrdaWarehouse::Hud::Client
      end
    end

    def most_recent_rrh_assessment(client)
      client.source_hmis_forms.rrh_assessment.newest_first.limit(1).first
    end

    def most_recent_pathways_assessment(client)
      client.source_hmis_forms.pathways.newest_first.limit(1).first
    end
  end
end
