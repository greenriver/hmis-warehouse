###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Generators::Fy2023
  class MeasureBase < ::HudReports::QuestionBase
    def self.client_class
      HudSpmReport::Fy2023::SpmEnrollment
    end

    private def enrollment_set
      enrollments = @report.spm_enrollments
      return enrollments if enrollments.exists?

      HudSpmReport::Fy2023::SpmEnrollment.create_enrollment_set(@report)
      @report.spm_enrollments
    end

    private def prepare_table(table_name, rows, cols, external_column_header: false, external_row_label: false)
      @report.answer(question: table_name).update(
        metadata: {
          header_row: [''] + cols.values,
          row_labels: rows.values,
          first_column: cols.keys.first,
          last_column: cols.keys.last,
          first_row: rows.keys.first,
          last_row: rows.keys.last,
          external_column_header: external_column_header,
          external_row_label: external_row_label,
        },
      )
    end

    private def spm_e_t
      HudSpmReport::Fy2023::SpmEnrollment.arel_table
    end

    private def percent(num, denom)
      return '0.00' if denom.zero?

      format('%1.4f', ((num / denom.to_f) * 100).round(2))
    end

    private def filter
      @filter ||= ::Filters::HudFilterBase.new(user_id: @report.user.id).update(@report.options)
    end

    private def generator_klass
      HudSpmReport::Generators::Fy2023::Generator
    end

    private def write_detail(answer)
      answer.write_detail(
        path: generator_klass.write_detail_path,
        generator: generator_klass,
        question_name: self.class.question_number,
      )
    end
  end
end
