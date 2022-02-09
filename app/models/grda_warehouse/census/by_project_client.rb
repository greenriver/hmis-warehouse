###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: this has been removed from use around 12/2018
module GrdaWarehouse::Census
  class ByProjectClient < Base
    self.table_name = "nightly_census_by_project_clients"

    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', optional: true

    scope :by_project_id, -> (project_id) do
      where(project_id: project_id)
    end

    scope :by_data_source_id, -> (data_source_id) do
      joins(:project).merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id))
    end

    scope :by_organization_id, -> (organization_id) do
      joins(project: :organization).merge(GrdaWarehouse::Hud::Organization.where(id: organization_id))
    end

    scope :for_date_range, -> (start_date, end_date) do
      where(date: start_date.to_date .. end_date.to_date).order(:date)
    end

    scope :night_by_night, -> do
      joins(:project).merge(GrdaWarehouse::Hud::Project.night_by_night)
    end
  end
end
