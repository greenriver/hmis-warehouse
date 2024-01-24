###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2023::Detail
  extend ActiveSupport::Concern

  included do
    private_class_method def self.header_label(col)
      case col.to_sym
      when :client_id
        'Warehouse Client ID'
      when :personal_id
        'HMIS Personal ID'
      when :data_source_id
        'Data Source ID'
      when :los_under_threshold
        'LOS Under Threshold'
      when :previous_street_essh
        'Previous Street ESSH'
      else
        col.humanize
      end
    end
  end
end
