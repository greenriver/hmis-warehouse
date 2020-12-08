###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Project < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::Project
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_projects'

    has_one :destination_record, **hud_assoc(:ProjectID, 'Project')

    GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.each do |k, v|
      scope k, -> { where(ProjectType: v) }
      define_method "#{k}?" do
        v.include? self[ProjectType]
      end
    end

    scope :night_by_night, -> do
      where(TrackingMethod: 3)
    end

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable  Lint/UnusedMethodArgument
      return none unless project_ids.present?

      warehouse_class.where(data_source_id: data_source_id, ProjectID: project_ids)
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Project
    end
  end
end
