###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports::Pit::Fy2017
  class ByProject < Base
    def self.report_name
      'PIT By Project - FY 2017'
    end

    def has_options?
      true
    end

    def has_project_option?
      true
    end

    def title_for_options
      'Project, PIT & Chronic dates'
    end

    def value_for_options options
      p_id, ds_id = JSON.parse(options['project'])
      project = GrdaWarehouse::Hud::Project.includes(:data_source).where(ProjectID: p_id, data_source_id: ds_id).first
      "#{project.ProjectName} - #{project.data_source.short_name}<br/> PIT: #{options['pit_date']}, Chronic: #{options['chronic_date']}".html_safe
    end

    def self.available_projects_for_filtering
      GrdaWarehouse::Hud::Project.joins(:data_source).merge(GrdaWarehouse::DataSource.order(:short_name)).order(:ProjectName).pluck(:ProjectName, :ProjectID, :data_source_id, :short_name).map do |name,id,ds_id,short_name|
        ["#{name} - #{short_name}", [id,ds_id]]
      end
    end
  end
end
