###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'roo'

# One-time import: Link Narrative extract → Case Notes in the Link project.
# File columns: MCI_UNIQ_ID, CONTACT_DATE, CONTACT_TYPE, NOTES
# - Resolves client by MCI Unique ID; skips row if not found.
# - Uses or creates a one-day enrollment in the Link project for the contact date.
# - Creates CustomCaseNote; stores CONTACT_TYPE as a CDED (contact method key: CONTACT_METHOD_CDED_KEY). The CDED must exist (raises if not).
#
# When dry_run is true, NO database changes are made. When dry_run is false, all writes run in a single transaction.
#
# Usage: HmisExternalApis::AcHmis::ImportLinkNarrative20260318.new(file_path, project_id, dry_run: true).perform
module HmisExternalApis
  module AcHmis
    class ImportLinkNarrative20260318
      BATCH_SIZE = 2_000
      EXPECTED_HEADERS = ['MCI_UNIQ_ID', 'CONTACT_DATE', 'CONTACT_TYPE', 'NOTES'].freeze
      CONTACT_METHOD_CDED_KEY = 'link_narrative_contact_method'

      attr_reader :file_path, :project_id, :dry_run, :stats

      def initialize(file_path, project_id, dry_run: false)
        @file_path = file_path
        @project_id = project_id
        @dry_run = dry_run
        @stats = {
          rows_processed: 0,
          skipped_client_not_found: 0,
          skipped_invalid_date: 0,
          enrollments_created: 0,
          case_notes_created: 0,
          cdes_created: 0,
          errors: [],
        }
      end

      def perform
        validate!
        log 'Building MCI Unique ID → client lookup...'
        build_mci_to_client!
        log "Link project: #{link_project.ProjectName} (id=#{link_project.id})"
        log "Contact method CDED key: #{CONTACT_METHOD_CDED_KEY}"
        log 'Streaming XLSX and processing in batches...'
        if dry_run
          log 'DRY RUN — no database changes will be made.'
          stream_and_process_batches!
        else
          PaperTrail.request(enabled: false) do
            Hmis::Hud::Base.transaction do
              stream_and_process_batches!
            end
          end
        end
        log "Done. #{stats_summary}"
        stats
      end

      private

      def validate!
        raise "file not found: #{file_path}" unless File.exist?(file_path)
        raise 'project_id required' unless project_id.present?
        raise "project not found: #{project_id}" unless link_project
        raise "contact method CDED key not found: #{CONTACT_METHOD_CDED_KEY}" unless contact_type_cded
      end

      def build_mci_to_client!
        # Lookup: MCI Unique ID -> source client id (keys normalized to string for file lookups)
        @mci_to_client_id = HmisExternalApis::ExternalId.mci_unique_ids.
          joins(:source).
          pluck(:value, :source_id).
          to_h { |value, id| [value.to_s, id] }
        # Lookup: source client id -> personal_id
        @client_info = Hmis::Hud::Client.where(data_source_id: data_source.id).
          where(id: @mci_to_client_id.values.uniq).
          pluck(:id, :personal_id).
          to_h

        log "  #{@mci_to_client_id.size} MCI Unique IDs in HMIS"
      end

      def link_project
        @link_project ||= Hmis::Hud::Project.hmis.find_by(id: project_id)
      end

      def data_source
        @data_source ||= link_project.data_source
      end

      def system_user
        @system_user ||= Hmis::Hud::User.system_user(data_source_id: data_source.id)
      end

      def contact_type_cded
        @contact_type_cded ||= Hmis::Hud::CustomDataElementDefinition.
          for_type(Hmis::Hud::CustomCaseNote.name).
          find_by(key: CONTACT_METHOD_CDED_KEY, data_source_id: data_source.id)
      end

      def stream_and_process_batches!
        xlsx = Roo::Excelx.new(file_path)
        sheet = xlsx.sheet(0)
        headers = sheet.row(1).map { |c| c.to_s.strip }
        missing = EXPECTED_HEADERS - headers
        raise "Missing columns: #{missing.join(', ')}. Found: #{headers.inspect}" if missing.any?

        col = headers.each_with_index.to_h
        batch = []
        row_num = 1

        sheet.each_row_streaming(offset: 1, pad_cells: true) do |row|
          row_num += 1
          batch << parse_row(row, col, row_num)
          next unless batch.size >= BATCH_SIZE

          process_batch!(batch.compact)
          batch = []
          GC.start
        end
        process_batch!(batch.compact) if batch.any?
      end

      def parse_row(row, col, row_num)
        mci = cell(row, col['MCI_UNIQ_ID'])
        return nil if mci.blank?

        client_id = @mci_to_client_id[mci.to_s]
        unless client_id
          @stats[:skipped_client_not_found] += 1
          return nil
        end

        personal_id = @client_info[client_id]
        unless personal_id
          @stats[:skipped_client_not_found] += 1
          return nil
        end

        date_raw = cell(row, col['CONTACT_DATE'])
        contact_timestamp = parse_contact_timestamp(date_raw)
        unless contact_timestamp
          @stats[:skipped_invalid_date] += 1
          return nil
        end
        contact_date = contact_timestamp.to_date

        {
          row_num: row_num,
          client_id: client_id,
          personal_id: personal_id,
          contact_date: contact_date,
          contact_timestamp: contact_timestamp,
          contact_type: cell(row, col['CONTACT_TYPE'])&.to_s&.strip.presence,
          notes: cell(row, col['NOTES'])&.to_s&.strip.presence || '',
        }
      end

      def cell(row, idx)
        row[idx]&.value
      end

      # Parses CONTACT_DATE (e.g. "1/3/2022  8:37:00 AM") to a Time for DateCreated/DateUpdated.
      # Also handles Excel numeric date, Time/DateTime from Roo, or Date.
      def parse_contact_timestamp(val)
        str = val&.to_s&.strip
        return nil if str.blank?

        Time.zone.parse(str)
      rescue ArgumentError, TypeError
        nil
      end

      def process_batch!(rows)
        return if rows.empty?

        @stats[:rows_processed] += rows.size
        now = Time.current

        # Resolve enrollments: (client_id, contact_date) -> enrollment (with EnrollmentID, PersonalID)
        enrollment_by_key = resolve_enrollments_for_batch(rows)

        # Create missing one-day enrollments (skipped when dry_run — no DB changes)
        unless dry_run
          rows.each do |r|
            key = [r[:client_id], r[:contact_date]]
            next if enrollment_by_key[key]

            en = create_one_day_enrollment!(r[:client_id], r[:personal_id], r[:contact_date], r[:contact_timestamp])
            enrollment_by_key[key] = en if en
          end
        end

        # Build case notes for rows that have an enrollment
        case_notes = []
        note_contact_types = [] # same index as case_notes for CONTACT_TYPE value (CDED)
        rows.each do |r|
          key = [r[:client_id], r[:contact_date]]
          en = enrollment_by_key[key]
          next unless en

          case_notes << Hmis::Hud::CustomCaseNote.new(
            CustomCaseNoteID: Hmis::Hud::Base.generate_uuid,
            EnrollmentID: en[:enrollment_id],
            PersonalID: en[:personal_id],
            data_source_id: data_source.id,
            content: r[:notes],
            information_date: r[:contact_date],
            UserID: system_user.UserID,
            DateCreated: r[:contact_timestamp],
            DateUpdated: r[:contact_timestamp],
          )
          note_contact_types << r[:contact_type].presence
        end

        # Import case notes and CDEs (skipped when dry_run — no DB changes)
        return if dry_run

        result = Hmis::Hud::CustomCaseNote.import(case_notes, validate: false, track_validation_failures: true)
        if result.failed_instances.any?
          result.failed_instances.each { |f| @stats[:errors] << "Case note row: #{f.errors.full_messages.join(', ')}" }
          raise "Batch failed: #{result.failed_instances.size} case notes"
        end

        @stats[:case_notes_created] += case_notes.size

        return unless result.ids.present?

        cdes = result.ids.each_with_index.filter_map do |owner_id, i|
          next if note_contact_types[i].blank?

          {
            owner_type: Hmis::Hud::CustomCaseNote.name,
            owner_id: owner_id,
            data_source_id: data_source.id,
            data_element_definition_id: contact_type_cded.id,
            value_string: note_contact_types[i],
            'UserID' => system_user.UserID,
            'DateCreated' => now,
            'DateUpdated' => now,
          }
        end

        return unless cdes.any?

        Hmis::Hud::CustomDataElement.insert_all(cdes)
        @stats[:cdes_created] += cdes.size
      end

      def resolve_enrollments_for_batch(rows)
        batch_personal_ids = rows.map { |r| r[:personal_id] }.uniq
        enrollments_by_client_id = link_project.enrollments.
          where(personal_id: batch_personal_ids).
          includes(:exit, :client).
          order(entry_date: :asc, id: :asc).
          group_by { |e| e.client.id }

        out = {}
        rows.each do |r|
          key = [r[:client_id], r[:contact_date]]
          next if out.key?(key) # already found

          client_enrollments = enrollments_by_client_id[r[:client_id]] || []
          # Find open enrollment that overlaps with the contact date
          found = client_enrollments.find do |e|
            entry = e.entry_date
            ex_date = e.exit&.exit_date
            entry <= r[:contact_date] && (ex_date.blank? || ex_date >= r[:contact_date])
          end
          next unless found # No enrollment found for this client on this date

          # Use HUD EnrollmentID (UUID), not the table's primary key (id)
          out[key] = { enrollment_id: found.enrollment_id, personal_id: found.client.personal_id }
        end
        out
      end

      def coc_code
        @coc_code ||= link_project.uniq_coc_codes.first.presence || 'XX-500'
      end

      def create_one_day_enrollment!(client_id, personal_id, contact_date, creation_timestamp)
        enrollment = Hmis::Hud::Enrollment.new(
          project_pk: link_project.id,
          project_id: link_project.project_id,
          data_source_id: data_source.id,
          personal_id: personal_id,
          EnrollmentID: Hmis::Hud::Base.generate_uuid,
          EntryDate: contact_date,
          RelationshipToHoH: 1,
          HouseholdID: Hmis::Hud::Base.generate_uuid,
          DisablingCondition: 99,
          EnrollmentCoC: coc_code,
          ExportID: 'link-narrative-import-03-2026',
          DateCreated: creation_timestamp,
          DateUpdated: creation_timestamp,
          UserID: system_user.UserID,
        )
        enrollment.save_new_enrollment!

        # FIXME: use a shared util for this.
        exit_record = Hmis::Hud::Exit.new(
          ExitID: Hmis::Hud::Base.generate_uuid,
          enrollment: enrollment,
          EnrollmentID: enrollment.EnrollmentID,
          PersonalID: personal_id,
          ExitDate: contact_date,
          Destination: 99,
          AssessmentDisposition: 99,
          ExportID: 'link-narrative-import',
          DateCreated: creation_timestamp,
          DateUpdated: creation_timestamp,
          UserID: system_user.UserID,
          data_source_id: data_source.id,
        )
        exit_record.save!

        @stats[:enrollments_created] += 1
        { enrollment_id: enrollment.enrollment_id, personal_id: personal_id }
      rescue StandardError => e
        @stats[:errors] << "Row (client_id=#{client_id}, date=#{contact_date}): #{e.message}"
        nil
      end

      def stats_summary
        "processed=#{@stats[:rows_processed]} skipped_client=#{@stats[:skipped_client_not_found]} skipped_date=#{@stats[:skipped_invalid_date]} enrollments_created=#{@stats[:enrollments_created]} case_notes_created=#{@stats[:case_notes_created]} cdes_created=#{@stats[:cdes_created]} errors=#{@stats[:errors].size}"
      end

      def log(msg)
        Rails.logger.info "[ImportLinkNarrative20260318] #{msg}"
        puts "[ImportLinkNarrative20260318] #{msg}"
      end
    end
  end
end
