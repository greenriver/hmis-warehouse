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

    def initialize(patient:, user:)
      @patient = patient
      @user = user
    end

    # Export PDFs for all configured health document types belonging to the patient.
    #
    # Creates one subdirectory per document type under +path+, writes each generated PDF as
    # +{record_id}-{label}.pdf+, and continues when individual records fail or have no content.
    #
    # @param path [String] base directory for the export (subdirectories are created as needed)
    # @return [Hash{Symbol=>Array}] +:exported+ file paths written, +:skipped+ record refs with blank
    #   content, +:errors+ hashes with +:ref+, +:message+, and +:backtrace+ for failures
    def export(path:)
      exported = []
      skipped = []
      errors = []

      EXPORT_CONFIGS.each do |config|
        subdir = File.join(path, patient_id, config[:subdir])
        FileUtils.mkdir_p(subdir)

        @patient.send(config[:association]).each do |record|
          ref = "#{config[:label]}##{record.id}"
          begin
            pdf_bytes = config[:generator].call(@user, record)
            if pdf_bytes.blank?
              skipped << ref
              next
            end

            filename = "#{record.id}-#{config[:label]}.pdf"
            file_path = File.join(subdir, filename)
            File.binwrite(file_path, pdf_bytes)
            exported << file_path
          rescue StandardError => e
            errors << { ref: ref, message: e.message, backtrace: e.backtrace.first(5) }
          end
        end
      end

      { exported: exported, skipped: skipped, errors: errors }
    end

    private def patient_id
      (@patient.medicaid_id.presence || @patient.id).to_s
    end
  end
end
