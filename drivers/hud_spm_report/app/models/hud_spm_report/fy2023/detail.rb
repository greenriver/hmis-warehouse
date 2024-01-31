###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2023::Detail
  extend ActiveSupport::Concern

  included do
    private_class_method def self.header_label(col)
      case col.to_s
      when 'client_id'
        'Warehouse Client ID'
      when 'personal_id', 'enrollment.personal_id', 'exit_enrollment.personal_id'
        'HMIS Personal ID'
      when 'enrollment.first_name', 'exit_enrollment.first_name'
        'First Name'
      when 'enrollment.last_name', 'exit_enrollment.last_name'
        'Last Name'
      when 'exit_enrollment.enrollment.project.project_name'
        'Exited Project Name'
      when 'return_enrollment.enrollment.project.project_name'
        'Returned Project Name'
      when 'data_source_id'
        'Data Source ID'
      when 'los_under_threshold'
        'LOS Under Threshold'
      when 'previous_street_essh'
        'Previous Street ESSH'
      else
        col.humanize
      end
    end
  end
end
