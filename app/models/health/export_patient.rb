###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Health
  class ExportPatient
    EXPORT_CONFIGS = [
      {
        association: :careplans,
        subdir: 'health_careplans',
        label: 'careplan',
        generator: ->(user, record) { Health::DocumentExports::CareplanPdfExport.generate(user: user, careplan: record) },
      },
      {
        association: :pctps,
        subdir: 'health_pctp_careplans',
        label: 'pctp_careplan',
        generator: ->(user, record) { HealthPctp::DocumentExports::PctpCareplanPdfExport.generate(user: user, careplan: record) },
      },
      {
        association: :comprehensive_health_assessments,
        subdir: 'health_comprehensive_health_assessments',
        label: 'cha',
        generator: ->(_user, record) { record.health_file&.content },
      },
      {
        association: :comprehensive_assessments,
        subdir: 'health_comprehensive_assessments',
        label: 'ca',
        generator: ->(user, record) { HealthComprehensiveAssessment::DocumentExports::CaAssessmentPdfExport.generate(user: user, assessment: record) },
      },
      {
        association: :self_sufficiency_matrix_forms,
        subdir: 'health_ssm_forms',
        label: 'ssm',
        generator: ->(user, record) { Health::DocumentExports::SelfSufficiencyMatrixFormPdfExport.generate(user: user, assessment: record) },
      },
      {
        association: :thrive_assessments,
        subdir: 'health_thrive_assessments',
        label: 'thrive',
        generator: ->(user, record) { HealthThriveAssessment::DocumentExports::ThriveAssessmentPdfExport.generate(user: user, assessment: record) },
      },
      {
        association: :participation_forms,
        subdir: 'health_participation_forms',
        label: 'participation_form',
        generator: ->(_user, record) { record.health_file&.content },
      },
      {
        association: :release_forms,
        subdir: 'health_release_forms',
        label: 'release_form',
        generator: ->(_user, record) { record.health_file&.content },
      },
      {
        association: :sdh_case_management_notes,
        subdir: 'health_sdh_case_management_notes',
        label: 'sdh_cm_note',
        generator: ->(_user, record) { record.health_file&.content },
      },
    ].freeze

    def initialize(patient:, user:, min_modification_date: nil)
      @patient = patient
      @user = user
      @min_modification_date = min_modification_date
    end

    # Export PDFs for all configured health document types belonging to the patient.
    #
    # Creates one subdirectory per document type under +path+, writes each generated PDF as
    # +{record_id}--{date}-{label}.pdf+, and continues when individual records fail or have no content.
    #
    # @param path [String] base directory for the export (subdirectories are created as needed)
    # @return [Hash{Symbol=>Array}] +:exported+ file paths written, +:skipped+ record refs with blank
    #   content, +:errors+ hashes with +:ref+, +:message+, and +:backtrace+ for failures
    def export(path:)
      exported = []
      skipped = []
      errors = []

      EXPORT_CONFIGS.each do |config|
        subdir = export_subdir(path, config[:subdir])
        FileUtils.mkdir_p(subdir)

        @patient.send(config[:association]).each do |record|
          # If we can determine a date, and we specified a min modification date
          # and the date is strictly before the min modification date, skip the record
          modification_date = record_export_date(record)
          next if modification_date.present? && @min_modification_date.present? && modification_date.to_date < @min_modification_date

          ref = "#{config[:label]}##{record.id}"
          begin
            pdf_bytes = config[:generator].call(@user, record)
            if pdf_bytes.blank?
              skipped << ref
              next
            end

            file_path = File.join(subdir, export_filename(record, label: config[:label]))
            File.binwrite(file_path, pdf_bytes)
            exported << file_path
          rescue StandardError => e
            errors << { ref: ref, message: e.message, backtrace: e.backtrace.first(5) }
          end
        end
      end

      { exported: exported, skipped: skipped, errors: errors }
    end

    # Patient folder name under the export root (medicaid_id, or patient id as fallback).
    def export_folder
      (@patient.medicaid_id.presence || @patient.id).to_s
    end

    def export_subdir(path, subdir_name)
      File.join(path, export_folder, subdir_name)
    end

    def export_filename(record, label:)
      "#{record.id}--#{record_export_date(record)}-#{label}.pdf"
    end

    private

    # Most files have created_at
    # participation and release forms don't have created_at, but do have a signature_on date
    # If we can't find a date, use an empty string
    def record_export_date(record)
      if record.respond_to?(:created_at) && record.created_at
        record.created_at.strftime('%Y-%m-%d')
      elsif record.respond_to?(:signature_on) && record.signature_on
        record.signature_on.strftime('%Y-%m-%d')
      else
        ''
      end
    end
  end
end
