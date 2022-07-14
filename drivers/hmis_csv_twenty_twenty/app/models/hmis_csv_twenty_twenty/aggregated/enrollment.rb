###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Aggregated
  class Enrollment < GrdaWarehouse::Hud::Base
    include ::HmisStructure::Enrollment
    include HmisCsvTwentyTwenty::Importer::ImportConcern
    include AggregatedImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_aggregated_enrollments'

    has_one :destination_record, **hud_assoc(:EnrollmentID, 'Enrollment')
    has_one :exit, primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], class_name: 'HmisCsvTwentyTwenty::Aggregated::Exit', autosave: false
    belongs_to :project, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], class_name: 'HmisCsvTwentyTwenty::Importer::Project', autosave: false, optional: true

    scope :open_during_range, ->(range) do
      e_t = arel_table
      ex_t = HmisCsvTwentyTwenty::Aggregated::Exit.arel_table
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

      warehouse_class.joins(:project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
        open_during_range(date_range.range)
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Enrollment
    end
  end
end
