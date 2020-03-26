###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ClientHealthEmergency
  extend ActiveSupport::Concern
  included do
    has_many :health_emergency_triages, class_name: '::GrdaWarehouse::HealthEmergency::Triage'
    has_many :health_emergency_test, class_name: '::GrdaWarehouse::HealthEmergency::Test'
    has_many :health_emergency_isolations, class_name: '::GrdaWarehouse::HealthEmergency::Isolation'
    has_many :health_emergency_quarantines, class_name: '::GrdaWarehouse::HealthEmergency::Quarantine'
    has_many :health_emergency_isolations_or_quarantines, class_name: '::GrdaWarehouse::HealthEmergency::IsolationBase'
  end

  # NOTE: these get pre-loaded so we should avoid pushing sorting to the DB
  def health_emergency_triage_status
    health_emergency_triages&.max_by(&:created_at)&.status || 'Unknown'
  end

  def health_emergency_test_status
    health_emergency_test&.max_by(&:created_at)&.status || 'Unknown'
  end

  def health_emergency_isolation_status
    isolations = [
      health_emergency_isolations&.max_by(&:created_at),
      health_emergency_quarantines&.max_by(&:created_at),
    ].compact
    return 'Unknown' unless isolations

    isolations.max_by(&:created_at)&.status || 'Unknown'
  end
end
