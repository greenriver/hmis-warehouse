###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Census
  class ByProject < Base
    include TsqlImport
    self.table_name = 'nightly_census_by_projects'

    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', optional: true

    scope :by_project_id, ->(project_id) do
      where(project_id: project_id)
    end

    scope :by_data_source_id, ->(data_source_id) do
      joins(:project).merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id))
    end

    scope :by_organization_id, ->(organization_id) do
      joins(project: :organization).merge(GrdaWarehouse::Hud::Organization.where(id: organization_id))
    end

    scope :by_project_type, ->(project_types) do
      joins(:project).merge(GrdaWarehouse::Hud::Project.with_project_type(project_types))
    end

    scope :for_date_range, ->(start_date, end_date) do
      where(date: start_date.to_date .. end_date.to_date).order(:date)
    end

    def self.view_column_names
      [
        'id',
        'date',
        'project_id',
        'veterans',
        'non_veterans',
        'children',
        'adults',
        'all_clients',
        'beds',
      ]
    end
  end
end
