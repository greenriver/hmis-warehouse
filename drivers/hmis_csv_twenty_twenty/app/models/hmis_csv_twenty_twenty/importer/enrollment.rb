###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Enrollment < GrdaWarehouse::Hud::Base
    include ::HmisStructure::Enrollment
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_enrollments'

    has_one :destination_record, **hud_assoc(:EnrollmentID, 'Enrollment')
    has_one :exit, primary_key: [:EnrollmentID, :PersonalID, :data_source_id, :importer_log_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id, :importer_log_id], class_name: 'HmisCsvTwentyTwenty::Importer::Exit', autosave: false
    belongs_to :project, primary_key: [:ProjectID, :data_source_id, :importer_log_id], foreign_key: [:ProjectID, :data_source_id, :importer_log_id], class_name: 'HmisCsvTwentyTwenty::Importer::Project', autosave: false, optional: true
    belongs_to :client, primary_key: [:PersonalID, :data_source_id, :importer_log_id], foreign_key: [:PersonalID, :data_source_id, :importer_log_id], class_name: 'HmisCsvTwentyTwenty::Importer::Client', autosave: false, optional: true
    has_many :services, primary_key: [:EnrollmentID, :data_source_id, :importer_log_id], foreign_key: [:EnrollmentID, :data_source_id, :importer_log_id], class_name: 'HmisCsvTwentyTwenty::Importer::Service', autosave: false
    has_many :current_living_situations, primary_key: [:EnrollmentID, :data_source_id, :importer_log_id], foreign_key: [:EnrollmentID, :data_source_id, :importer_log_id], class_name: 'HmisCsvTwentyTwenty::Importer::CurrentLivingSituation', autosave: false

    scope :open_during_range, ->(range) do
      e_t = arel_table
      ex_t = HmisCsvTwentyTwenty::Importer::Exit.arel_table
      # convert the range into a standard range for backwards compatability
      range = (range.start..range.end) if range.is_a?(::Filters::DateRange)
      d_1_start = range.first
      d_1_end = range.last
      d_2_start = e_t[:EntryDate]
      d_2_end = ex_t[:ExitDate]
      # Currently does not count as an overlap if one starts on the end of the other
      left_outer_joins(:exit).
        where(d_2_end.gt(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lt(d_1_end)))
    end

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return none unless project_ids.present?

      warehouse_class.importable.joins(:project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
        open_during_range(date_range.range)
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Enrollment
    end

    def self.complex_validations
      [
        {
          class: HmisCsvValidation::OneHeadOfHousehold,
        },
        {
          class: HmisCsvValidation::EntryAfterExit,
        },
        {
          class: HmisCsvValidation::UniqueHudKey,
        },
      ]
    end

    def self.hmis_validations
      {
        PersonalID: [
          class: HmisCsvValidation::NonBlank,
        ],
        ProjectID: [
          class: HmisCsvValidation::NonBlank,
        ],
        EntryDate: [
          class: HmisCsvValidation::NonBlank,
        ],
        HouseholdID: [
          class: HmisCsvValidation::NonBlankValidation,
        ],
        RelationshipToHoH: [
          {
            class: HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility.relationships_to_hoh.keys.map(&:to_s).freeze },
          },
        ],
        LivingSituation: [
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility.available_situations.keys.map(&:to_s).freeze },
          },
        ],
        LengthOfStay: [
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility.length_of_stays.keys.map(&:to_s).freeze },
          },
        ],
        DisablingCondition: [
          {
            class: HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility.no_yes_reasons_for_missing_data_options.keys.map(&:to_s).freeze },
          },
        ],
      }
    end
  end
end
