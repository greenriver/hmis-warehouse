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

    def export(path:)
      exported = []
      skipped = []

      EXPORT_CONFIGS.each do |config|
        subdir = File.join(path, config[:subdir])
        FileUtils.mkdir_p(subdir)

        @patient.send(config[:association]).each do |record|
          pdf_bytes = config[:generator].call(@user, record)
          if pdf_bytes.blank?
            skipped << "#{config[:label]}##{record.id}"
            next
          end

          filename = "#{record.id}-#{config[:label]}.pdf"
          File.binwrite(File.join(subdir, filename), pdf_bytes)
          exported << filename
        end
      end

      { exported: exported, skipped: skipped }
    end
  end
end
