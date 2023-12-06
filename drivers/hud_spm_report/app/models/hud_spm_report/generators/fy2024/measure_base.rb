###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Generators::Fy2024
  class MeasureBase < ::HudReports::QuestionBase
    private def enrollment_set
      enrollments ||= @report.spm_enrollments
      return enrollments if enrollments.present?

      HudSpmReport::Fy2024::SpmEnrollment.create_enrollment_set(@report)
      @report.spm_enrollments
    end

    private def prepare_table(table_name, rows, cols)
      @report.answer(question: table_name).update(
        metadata: {
          header_row: [''] + cols.values,
          row_labels: rows.values,
          first_column: cols.keys.first,
          last_column: cols.keys.last,
          first_row: rows.keys.first,
          last_row: rows.keys.last,
        },
      )
    end

    private def spm_e_t
      HudSpmReport::Fy2024::SpmEnrollment.arel_table
    end

    private def percent(num, denom)
      return 0.0 if denom.zero?

      ((num / denom.to_f) * 100).round(2)
    end
  end
end
