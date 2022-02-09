###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class Scan < ::Filters::FilterBase
    attribute :service_type, String, default: 'ServiceScanning::BedNight'
    attribute :other_type, String, default: ''

    def set_from_params(filters) # rubocop:disable Naming/AccessorMethodName
      return super unless filters.present?

      super
      self.service_type = filters.dig(:service_type)&.to_sym
      self.other_type = filters.dig(:other_type)
    end

    def all_project_scope
      GrdaWarehouse::Hud::Project.where(id: ServiceScanning::Service.distinct.select(:project_id)).viewable_by(user)
    end

    def default_start
      Date.current - 1.weeks
    end

    def default_end
      Date.current
    end

    def for_params
      additional = {
        filters: {
          service_type: service_type,
          other_type: other_type,
        },
      }
      super.deep_merge(additional)
    end

    def service_type_class
      ServiceScanning::Service.type_from_key(service_type).name
    end
  end
end

module ServiceScanning::Filters
  class Scan < ::Filters::Scan
  end
end
