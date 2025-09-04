###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis::Exporters
  class AltAhaCalculationLogExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter

    def initialize(output: StringIO.new, included_enrollment_ids: nil)
      require 'csv'
      self.output = output
      @included_enrollment_ids = included_enrollment_ids
    end

    # Generates the content of the Alt AHA Calculation Log export
    def run!
      Rails.logger.info 'Generating content of Alt AHA Calculation Log export'

      write_row(columns)
      total = calculation_logs.count

      Rails.logger.info "There are #{total} Alt AHA Calculation Logs to export"

      calculation_logs.find_each.with_index do |calculation_log, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 1000).zero?

        alt_aha_1 = calculation_log.calculation_details['alt_aha_1']
        alt_aha_2 = calculation_log.calculation_details['alt_aha_2']
        alt_aha_3 = calculation_log.calculation_details['alt_aha_3']
        total_points = calculation_log.calculation_details['total_points']
        values = [
          calculation_log.owner.id,     # EnrollmentID
          calculation_log.created_at,   # CreatedAt
          alt_aha_1['raw_score'],       # AltAha1RawScore
          alt_aha_1['probability'],     # AltAha1Probability
          alt_aha_1['points'],          # AltAha1Points
          alt_aha_2['raw_score'],       # AltAha2RawScore
          alt_aha_2['probability'],     # AltAha2Probability
          alt_aha_2['points'],          # AltAha2Points
          alt_aha_3['raw_score'],       # AltAha3RawScore
          alt_aha_3['probability'],     # AltAha3Probability
          alt_aha_3['points'],          # AltAha3Points
          total_points,                 # TotalPoints
          calculation_log.final_score,  # FinalScore
        ]
        write_row(values)
      end
    end

    private

    # backed by hmis_scoring_calculation_logs table
    def columns
      [
        'EnrollmentID',
        'CreatedAt',
        'AltAha1RawScore',
        'AltAha1Probability',
        'AltAha1Points',
        'AltAha2RawScore',
        'AltAha2Probability',
        'AltAha2Points',
        'AltAha3RawScore',
        'AltAha3Probability',
        'AltAha3Points',
        'TotalPoints',
        'FinalScore',
      ]
    end

    def calculation_logs
      return @calculation_logs if @calculation_logs

      scope = Hmis::Scoring::CalculationLog.where(namespace: HmisExternalApis::AcHmis::AltAhaCalculator::ALT_AHA_NAMESPACE)
      scope = scope.where(owner_id: @included_enrollment_ids, owner_type: 'Hmis::Hud::Enrollment') if @included_enrollment_ids
      @calculation_logs = scope
      @calculation_logs
    end
  end
end
