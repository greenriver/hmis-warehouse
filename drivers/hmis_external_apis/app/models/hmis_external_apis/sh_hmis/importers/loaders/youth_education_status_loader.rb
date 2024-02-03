###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# reload!; reader = HmisExternalApis::ShHmis::Importers::Loaders::CsvReader.new('drivers/hmis_external_apis/spec/fixtures/hmis_external_apis/sh_hmis/importers'); HmisExternalApis::ShHmis::Importers::Loaders::YouthEducationStatusLoader.new(clobber: false, reader: reader).perform
module HmisExternalApis::ShHmis::Importers::Loaders
  class YouthEducationStatusLoader < SingleFileLoader
    # Key so that we know which YouthEducationStatus were generated by this process, so that we can clobber them
    SOURCE_HASH = 'OP-HMIS-MIGRATION-2023'.freeze

    def perform
      records = build_records
      # destroy existing records and re-import
      model_class.where(data_source: data_source, source_hash: SOURCE_HASH).each(&:really_destroy!) if clobber
      ar_import(model_class, records)
    end

    def filename
      'EducationStatus.csv'
    end

    protected

    def build_records
      # { [EnrollmentID, InformationDate] => YouthEducationStatus record }
      records_by_key = {}

      enrollment_id_header = 'Unique Enrollment Identifier'
      enrollment_id_to_personal_id = Hmis::Hud::Enrollment.where(data_source: data_source).
        pluck(:enrollment_id, :personal_id).to_h
      enrollment_id_to_entry_date = Hmis::Hud::Enrollment.where(data_source: data_source).
        pluck(:enrollment_id, :entry_date).to_h
      enrollment_id_to_exit_date = Hmis::Hud::Enrollment.where(data_source: data_source).
        joins(:exit).
        pluck(:enrollment_id, Hmis::Hud::Exit.arel_table[:exit_date]).to_h

      expected = 0
      rows.map do |row|
        answer = row_value(row, field: 'Answer', required: false)
        next if answer.blank?

        enrollment_id = row_value(row, field: enrollment_id_header, required: false)
        next unless enrollment_id

        information_date = parse_date(row_value(row, field: 'Date Taken'))
        record_key = [enrollment_id, information_date]
        expected += 1 unless records_by_key.key?(record_key)

        personal_id = enrollment_id_to_personal_id[enrollment_id]
        unless personal_id
          log_skipped_row(row, field: enrollment_id_header)
          next # early return
        end

        records_by_key[record_key] ||= begin
          # Determine Data Collection Stage based on the information date
          entry_date = enrollment_id_to_entry_date[enrollment_id]
          exit_date = enrollment_id_to_exit_date[enrollment_id]
          data_collection_stage = if entry_date&.to_date == information_date.to_date
            1 # entry
          elsif exit_date&.to_date == information_date.to_date
            3 # exit
          else
            # NOTE: even though YouthEducationStatus is only collected at Entry/Exit per hud, we also collect
            # it on update assessments here. So, if the date falls between entry/exit, put it on an update.
            2 # update
          end

          {
            YouthEducationStatusID: Hmis::Hud::Base.generate_uuid,
            EnrollmentID: enrollment_id,
            PersonalID: personal_id,
            InformationDate: information_date.to_date,
            DataCollectionStage: data_collection_stage,
            DateCreated: information_date,
            DateUpdated: information_date,
            UserID: user_id_from_staff_id(row),
            data_source_id: data_source.id,
            source_hash: SOURCE_HASH,
          }
        end

        attributes_from_row = youth_education_status_attrs(row)
        records_by_key[record_key].merge!(attributes_from_row)
      end.compact

      records = records_by_key.values

      Rails.logger.info "Record count per DataCollectionStage: #{records.map { |h| HudUtility2024.data_collection_stage(h[:DataCollectionStage]) }.tally}"

      # For records with an "Update" stage, adjust them to be marked as Entry if there is no existing entry record
      # N^2, but its a small data set
      records.each do |attrs|
        next unless attrs[:DataCollectionStage] == 2

        # Other YouthEducationStatus records for this enrollment
        other_records = records.filter { |obj| obj[:EnrollmentID] == attrs[:EnrollmentID] && obj[:YouthEducationStatusID] != attrs[:YouthEducationStatusID] }

        # Skip if already have an Entry record
        already_has_entry_record = other_records.detect { |obj| obj[:DataCollectionStage] == 1 }.present?
        next if already_has_entry_record

        # Skip if have another record with earlier entry date
        has_earlier_record = other_records.find { |obj| obj[:InformationDate] < attrs[:InformationDate] }
        next if has_earlier_record

        attrs[:DataCollectionStage] = 1
      end

      Rails.logger.info "Adjusted record count per DataCollectionStage: #{records.map { |h| HudUtility2024.data_collection_stage(h[:DataCollectionStage]) }.tally}"

      log_processed_result(expected: expected, actual: records_by_key.size)

      records.each do |record|
        record[:CurrentSchoolAttend] ||= 99
        record[:MostRecentEdStatus] ||= 99
        record[:CurrentEdStatus] ||= 99
      end

      records
    end

    def youth_education_status_attrs(row)
      question = row_value(row, field: 'Question')
      answer = row_value(row, field: 'Answer', required: false)
      return {} if answer.blank?

      answer = answer.gsub('Pursing', 'Pursuing') # clean typo

      attrs = case question
      when 'Current school enrollment and attendance'
        {
          CurrentSchoolAttend: HudUtility2024.current_school_attended(answer, true),
        }
      when 'C3.A'
        {
          MostRecentEdStatus: HudUtility2024.most_recent_ed_status(answer, true),
        }
      when 'C3.B'
        {
          CurrentEdStatus: HudUtility2024.current_ed_status(answer, true),
        }
      else
        # SKIPPED: 'Level of education' doesn't map to HUD field
        #  N/A
        #  YYA has completed high school or GED/HISET
        #  YYA is currently enrolled in college
        {}
      end

      Rails.logger.info("Unable to parse answer: #{answer}") if attrs.keys.any? && attrs.values.compact.empty?

      attrs
    end

    def model_class
      Hmis::Hud::YouthEducationStatus
    end
  end
end
