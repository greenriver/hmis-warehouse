###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module He
  class ClientsController < ApplicationController
    include ClientDependentControllers
    include HealthEmergencyController

    def boston_covid_19
      @triage = GrdaWarehouse::HealthEmergency::Triage.new(agency: current_user.agency)
      @clinical_triage = GrdaWarehouse::HealthEmergency::ClinicalTriage.new(agency: current_user.agency)
      @test = GrdaWarehouse::HealthEmergency::Test.new(agency: current_user.agency)
      @isolation = GrdaWarehouse::HealthEmergency::Isolation.new(agency: current_user.agency)
      @quarantine = GrdaWarehouse::HealthEmergency::Quarantine.new(agency: current_user.agency)
      @ama_restriction = GrdaWarehouse::HealthEmergency::AmaRestriction.new(agency: current_user.agency)
      @vaccination = GrdaWarehouse::HealthEmergency::Vaccination.new(agency: current_user.agency)

      @triages = @client.health_emergency_triages.newest_first.to_a
      @clinical_triages = @client.health_emergency_clinical_triages.newest_first.to_a
      @tests = @client.health_emergency_tests.newest_first.to_a
      @vaccinations = @client.health_emergency_vaccinations.newest_first.to_a
      @isolations = @client.health_emergency_isolations.newest_first.to_a
      @quarantines = @client.health_emergency_quarantines.newest_first.to_a
      @ama_restrictions = @client.health_emergency_ama_restrictions.newest_first.to_a

      @history = (@triages + @clinical_triages + @tests + @isolations + @quarantines + @ama_restrictions + @vaccinations)&.sort_by(&:sort_date)&.reverse

      @isolation_newer = calculate_isolations_status
      @last_clinical_triage = @clinical_triages.first
      @last_test = @tests.first
      @last_vaccination = @vaccinations.first
    end

    def covid_19_vaccinations_only
      @vaccination = GrdaWarehouse::HealthEmergency::Vaccination.new(agency: current_user.agency)

      @vaccinations = @client.health_emergency_vaccinations.newest_first.to_a

      @history = @vaccinations&.sort_by(&:sort_date)&.reverse

      @last_vaccination = @vaccinations.first
    end

    private def calculate_isolations_status
      return unless @isolations.any? || @quarantines.any?

      max_isolation_date = @isolations&.first&.created_at
      max_quarantine_date = @quarantines&.first&.created_at
      return max_isolation_date > max_quarantine_date if @isolations.any? && @quarantines.any?
      return true if @isolations.any?
      return false if @quarantines.any?
    end
  end
end
