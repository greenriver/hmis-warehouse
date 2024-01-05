###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthQaFactory::Health
  module PatientExtension
    extend ActiveSupport::Concern

    included do
      has_many :qa_factories, class_name: 'HealthQaFactory::Factory'
    end

    def current_qa_factory
      # If there is no factory, create one
      newest = qa_factories.order(created_at: :desc).first
      return qa_factories.create unless newest.present?

      # If the newest factory is not associated with a PCTP, it is has to be current
      return newest if newest.careplan.nil?

      # If the newest factory is associated with the current CP2 careplan, it is current
      careplan = recent_pctp_careplan&.instrument
      return newest if careplan&.cp2? && newest.careplan_id == careplan.id

      # Otherwise, create a new one
      qa_factories.create
    end
  end
end
