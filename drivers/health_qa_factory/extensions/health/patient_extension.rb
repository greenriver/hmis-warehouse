###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

      newest
    end

    def qa_factory_factory
      newest = current_qa_factory

      # If the newest factory is not associated with a PCTP,  use it
      return newest if newest.careplan.nil?

      # If the current factory is not complete,  use it
      return newest unless newest.complete?

      # Otherwise, create a new one
      qa_factories.create
    end
  end
end
