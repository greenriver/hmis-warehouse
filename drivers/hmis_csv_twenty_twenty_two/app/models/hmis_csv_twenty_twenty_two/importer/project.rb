###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Importer
  class Project < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::Project
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2022_projects'

    has_one :destination_record, **hud_assoc(:ProjectID, 'Project')

    GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.each do |k, v|
      scope k, -> { where(ProjectType: v) }
      define_method "#{k}?" do
        v.include? self[ProjectType]
      end
    end

    scope :residential, -> do
      where(ProjectType: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS)
    end

    scope :night_by_night, -> do
      where(TrackingMethod: 3)
    end

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable Lint/UnusedMethodArgument
      return none unless project_ids.present?

      warehouse_class.importable.where(data_source_id: data_source_id, ProjectID: project_ids)
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Project
    end

    def self.hmis_validations
      {
        ProjectID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        OrganizationID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        ProjectName: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        OperatingStartDate: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
        ],
        ContinuumProject: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.yes_no_missing_options.keys.map(&:to_s).freeze },
          },
        ],
        ProjectType: [
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.project_types.keys.map(&:to_s).freeze },
          },
        ],
        HousingType: [
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.housing_types.keys.map(&:to_s).freeze },
          },
        ],
        ResidentialAffiliation: [
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.yes_no_missing_options.keys.map(&:to_s).freeze },
          },
        ],
        TrackingMethod: [
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.tracking_methods.keys.map(&:to_s).freeze },
          },
        ],
        HMISParticipatingProject: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.yes_no_missing_options.keys.map(&:to_s).freeze },
          },
        ],
        TargetPopulation: [
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.target_populations.keys.map(&:to_s).freeze },
          },
        ],
        HOPWAMedAssistedLivingFac: [
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.h_o_p_w_a_med_assisted_living_facs.keys.map(&:to_s).freeze },
          },
        ],
      }
    end
  end
end
