###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

module HmisExternalApis::AcHmis::Exporters
  class CaseNoteExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter

    def run!
      Rails.logger.info 'Generating content of case note export'

      write_row(columns)
      total = case_notes.count

      Rails.logger.error "There are #{total} case notes to export. That doesn't look right" if total < 10

      case_notes.find_each.with_index do |case_note, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 1000).zero?

        warehouse_id = case_note.client.warehouse_id
        next unless warehouse_id.present? # Client doesn't have a destination client ID yet. Skip since it wont be in Client.csv anyway.

        values = [
          case_note.id,
          case_note.enrollment.id, # Matches EnrollmentID in HMIS CSV Export
          warehouse_id, # Matches PersonalID in HMIS CSV Export
          case_note.information_date,
          case_note.content,
          case_note.date_created,
          case_note.date_updated,
          case_note.user.id, # Matches User.csv in HMIS CSV Export
        ]
        write_row(values)
      end
    end

    def columns
      [
        'CaseNoteID',       # Unique internal id for this note. Matches RecordId in CustomFieldValues.csv
        'EnrollmentID',     # EnrollmentID matching HMIS CSV export (database id)
        'PersonalID',       # PersonalID matching HMIS CSV export (warehouse destination id)
        'InformationDate',  # Information Date collected with the note
        'NoteContent',      # Content of the note
        'DateCreated',      # Timestamp when the note was created
        'DateUpdated',      # Timestamp when the note was last updated
        'UserID',           # User who most recently updated the note. Join with User.csv in HMIS CSV Export to find name and email.
      ]
    end

    private

    def case_notes
      Hmis::Hud::CustomCaseNote.where(data_source: data_source).
        joins(:enrollment).
        merge(Hmis::Hud::Enrollment.not_in_progress). # drop WIP Enrollments, which won't be present in Enrollment.csv export
        preload(:enrollment, :user, client: :warehouse_client_source). # preload to get client destination id
        distinct
    end
  end
end
