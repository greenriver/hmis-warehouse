###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Aggregated
  class Enrollment < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::Enrollment
    include HmisCsvImporter::Importer::ImportConcern
    include AggregatedImportConcern

    self.table_name = 'hmis_aggregated_enrollments'

    has_one :destination_record, **hud_assoc(:EnrollmentID, 'Enrollment')
    has_one :exit, primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], class_name: 'HmisCsvImporter::Aggregated::Exit', autosave: false
    belongs_to :project, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], class_name: 'HmisCsvImporter::Importer::Project', autosave: false

    scope :open_during_range, ->(range) do
      e_t = arel_table
      ex_t = HmisCsvImporter::Aggregated::Exit.arel_table
      # convert the range into a standard range for backwards compatability
      range = (range.start..range.end) if range.is_a?(::Filters::DateRange)
      d_1_start = range.first
      d_1_end = range.last
      d_2_start = e_t[:EntryDate]
      d_2_end = ex_t[:ExitDate]
      # Currently does not count as an overlap if one starts on the end of the other
      joins(e_t.join(ex_t, Arel::Nodes::OuterJoin).
        on(e_t[:EnrollmentID].eq(ex_t[:EnrollmentID]).
        and(e_t[:PersonalID].eq(ex_t[:PersonalID]).
        and(e_t[:data_source_id].eq(ex_t[:data_source_id])))).
        join_sources).
        where(d_2_end.gteq(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lteq(d_1_end)))
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

    def self.migrate_to_unversioned
      names = column_names.map { |name| "\"#{name}\"" }.join(', ')
      connection.execute "INSERT INTO hmis_aggregated_enrollments (#{names}) SELECT #{names} FROM hmis_2020_aggregated_enrollments"
    end
  end
end
