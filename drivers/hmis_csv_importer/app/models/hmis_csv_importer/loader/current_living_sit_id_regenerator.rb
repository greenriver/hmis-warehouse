###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Loader
  # For vendors whose export numbers CurrentLivingSitID by row position, so the same
  # record gets a different ID on each export and each load overwrites unrelated records.
  class CurrentLivingSitIdRegenerator
    FILE_NAME = 'CurrentLivingSituation.csv'
    DUPLICATE_REASON = 'duplicate_current_living_situation'

    def self.description
      'Replace CurrentLivingSitID with a digest of EnrollmentID, PersonalID, InformationDate, CurrentLivingSituation, and DateCreated, for vendors whose CLS IDs are not stable between exports'
    end

    def self.associated_model
      :CurrentLivingSituation
    end

    def self.enable
      { pre_process_hooks: { name => true } }
    end

    def self.checked?(data_source)
      data_source[:pre_process_hooks][name] || false
    end

    def self.regenerate!(source_dir, loadable_files, loader_log)
      klass = loadable_files[FILE_NAME]
      file = File.join(source_dir, FILE_NAME)
      return unless klass && File.exist?(file)

      seen_ids = Set.new
      discarded_rows = []
      PreProcessCsv.rewrite!(file) do |row, csv|
        id = digest(
          enrollment_id: row['enrollmentid'],
          personal_id: row['personalid'],
          information_date: row['informationdate'],
          current_living_situation: row['currentlivingsituation'],
          date_created: row['datecreated'],
        )
        if seen_ids.add?(id)
          row['currentlivingsitid'] = id
          csv << row
        else
          discarded_rows << UnlinkedRecordFilter.build_discarded_row(loader_log: loader_log, file_name: FILE_NAME, klass: klass, row: row, reason: DUPLICATE_REASON)
          UnlinkedRecordFilter.import_discarded_rows!(discarded_rows) if discarded_rows.size >= UnlinkedRecordFilter::NOTE_IMPORT_BATCH_SIZE
        end
      end
      UnlinkedRecordFilter.import_discarded_rows!(discarded_rows)
    end

    # Must stay reproducible in SQL for the DBT pipeline, over the raw CSV strings (not
    # type-cast dates): md5(concat_ws('--', 'CurrentLivingSitID', coalesce(btrim(...), ''), ...)).
    # Rows sharing all five values get the same ID and only the first is kept, even if
    # other columns differ.
    def self.digest(enrollment_id:, personal_id:, information_date:, current_living_situation:, date_created:)
      values = [enrollment_id, personal_id, information_date, current_living_situation, date_created].map { |value| value.to_s.strip }
      Digest::MD5.hexdigest(['CurrentLivingSitID', *values].join('--'))
    end
  end
end
