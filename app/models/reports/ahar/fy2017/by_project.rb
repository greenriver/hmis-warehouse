###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports::Ahar::Fy2017
  class ByProject < Base
    def self.report_name
      'AHAR By Project - FY 2017'
    end

    def self.generator
      ReportGenerators::Ahar::Fy2017::ByProject
    end

    def self.available_options
      super + [:project_id]
    end

    def report_type
      0
    end

    def custom_form?
      true
    end

    def options?
      true
    end

    def project_id_option?
      true
    end

    def date_range_options?
      true
    end

    def title_for_options
      'Project'
    end

    def value_for_options options
      project = GrdaWarehouse::Hud::Project.find(options['project_id'].to_i)
      "#{project.ProjectName} - #{project.data_source.short_name}"
    end
  end
end
