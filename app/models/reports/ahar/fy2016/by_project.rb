###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports::Ahar::Fy2016
  class ByProject < Base
    def self.report_name
      'AHAR By Project - FY 2016'
    end

    def report_type
      0
    end

    def has_custom_form?
      true
    end

    def has_options?
      true
    end

    def has_project_option?
      true
    end

    def has_date_range_options?
      true
    end

    def title_for_options
      'Project'
    end

    def value_for_options options
      p_id, ds_id = JSON.parse(options['project'])
      project = GrdaWarehouse::Hud::Project.includes(:data_source).where(ProjectID: p_id, data_source_id: ds_id).first
      "#{project.ProjectName} - #{project.data_source.short_name}"
    end
  end
end
