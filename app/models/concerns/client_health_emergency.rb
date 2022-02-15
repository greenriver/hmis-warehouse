###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientHealthEmergency
  extend ActiveSupport::Concern
  included do
    has_many :health_emergency_triages, class_name: '::GrdaWarehouse::HealthEmergency::Triage'
    has_many :health_emergency_clinical_triages, class_name: '::GrdaWarehouse::HealthEmergency::ClinicalTriage'
    has_many :health_emergency_tests, class_name: '::GrdaWarehouse::HealthEmergency::Test'
    has_many :health_emergency_vaccinations, class_name: '::GrdaWarehouse::HealthEmergency::Vaccination'
    has_many :health_emergency_isolations, class_name: '::GrdaWarehouse::HealthEmergency::Isolation'
    has_many :health_emergency_quarantines, class_name: '::GrdaWarehouse::HealthEmergency::Quarantine'
    has_many :health_emergency_isolations_or_quarantines, class_name: '::GrdaWarehouse::HealthEmergency::IsolationBase'
    has_many :health_emergency_ama_restrictions, class_name: '::GrdaWarehouse::HealthEmergency::AmaRestriction'
  end

  # NOTE: these get pre-loaded so we should avoid pushing sorting to the DB
  def health_emergency_triage_status
    health_emergency_triages&.max_by(&:created_at)&.status || 'Unknown'
  end

  def health_emergency_clinical_triage_status
    health_emergency_clinical_triages&.max_by(&:created_at)&.status || 'Unknown'
  end

  def health_emergency_test_status
    health_emergency_tests&.max_by(&:created_at)&.status || 'Unknown'
  end

  def health_emergency_vaccination_status
    health_emergency_vaccinations&.max_by(&:created_at)&.status || 'Unknown'
  end

  def health_emergency_isolation_quarantine_pill_title
    most_recent_health_emergency_isolation_or_quarantine&.pill_title || 'Isolation'
  end

  def most_recent_health_emergency_isolation_or_quarantine
    @most_recent_health_emergency_isolation_or_quarantine ||= max_health_emergency_isolations_and_quarantines.max_by(&:created_at)
  end

  private def max_health_emergency_isolations_and_quarantines
    @max_health_emergency_isolations_and_quarantines ||= [
      health_emergency_isolations&.max_by(&:created_at),
      health_emergency_quarantines&.max_by(&:created_at),
    ].compact
  end

  def health_emergency_isolation_status
    return 'Unknown' unless max_health_emergency_isolations_and_quarantines

    most_recent_health_emergency_isolation_or_quarantine&.status || 'Unknown'
  end

  # Only show AMA if there is an active one
  def health_emergency_ama_restriction_status
    ama = health_emergency_ama_restrictions&.max_by(&:created_at)
    return unless ama.present?
    return unless ama.show_pill_in_search_results?

    ama.status
  end
end
