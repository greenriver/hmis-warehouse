###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::HmisCsvCleanup
  class MoveInOutsideEnrollment < Base
    def cleanup!
      e_t = enrollment_source.arel_table
      ex_t = exit_source.arel_table

      enrollment_batch = []

      invalid_move_in_dates = enrollment_scope.where(
        e_t[:MoveInDate].lt(e_t[:EntryDate]).
          or(ex_t[:ExitDate].not_eq(nil).and(e_t[:MoveInDate].gt(ex_t[:ExitDate]))),
      )
      # for some reason this query can be really slow if not analyzed prior to run
      conn = enrollment_source.connection
      conn.execute("ANALYZE #{conn.quote_table_name(e_t.name)}, #{conn.quote_table_name(ex_t.name)}")
      invalid_move_in_dates.find_each do |enrollment|
        enrollment.MoveInDate = nil
        enrollment.set_source_hash
        enrollment_batch << enrollment
      end

      enrollment_source.import(
        enrollment_batch,
        on_duplicate_key_update: {
          conflict_target: conflict_target(enrollment_source),
          columns: [:MoveInDate, :source_hash],
        },
      )
    end

    def enrollment_scope
      enrollment_source.
        left_outer_joins(:exit).
        where(importer_log_id: @importer_log.id)
    end

    def enrollment_source
      importable_file_class('Enrollment')
    end

    def exit_source
      importable_file_class('Exit')
    end

    def self.description
      'Remove move-in dates the occur before the entry, or after the exit'
    end

    def self.enable
      {
        import_cleanups: {
          'Enrollment': ['HmisCsvImporter::HmisCsvCleanup::MoveInOutsideEnrollment'],
        },
      }
    end
  end
end
