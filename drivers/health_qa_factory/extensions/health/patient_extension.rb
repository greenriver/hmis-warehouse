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
      newest = qa_factories.order(created_at: :desc).first
      return newest if newest.present? && ! newest.complete?

      qa_factories.create
    end
  end
end
