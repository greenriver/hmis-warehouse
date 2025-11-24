# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Minimal FY 2024 generator retained solely for viewing historical reports.
# The implementation intentionally avoids any data processing so that legacy
# report instances can be rendered without supporting new executions.
module HopwaCaper::Generators::Fy2024
  class Generator < ::HudReports::GeneratorBase
    UNSUPPORTED_MESSAGE = 'FY 2024 HOPWA CAPER reports are read-only'

    class << self
      def fiscal_year = 'FY 2024'
      def generic_title = 'HOPWA CAPER'
      def short_name = 'HOPWA CAPER'

      def file_prefix
        "#{short_name} #{fiscal_year}"
      end

      def default_project_type_codes
        HudHelper.util('2024').project_type_group_titles.keys
      end

      def questions
        [
          HopwaCaper::Generators::Fy2024::Sheets::DemographicsAndPriorLivingSituationSheet,
          HopwaCaper::Generators::Fy2024::Sheets::TbraSheet,
          HopwaCaper::Generators::Fy2024::Sheets::StrmuSheet,
          HopwaCaper::Generators::Fy2024::Sheets::PhpSheet,
        ].map { |klass| [klass.question_number, klass] }.to_h.freeze
      end

      def valid_question_number(question_number)
        question_number
      end

      def filter_class
        ::Filters::HudFilterBase
      end

      def allowed_options(_)
        HopwaCaper::Generators::Fy2026::Generator.allowed_options(nil)
      end
    end

    def queue
      raise NotImplementedError, UNSUPPORTED_MESSAGE
    end

    def run!(*)
      raise NotImplementedError, UNSUPPORTED_MESSAGE
    end

    def prepare_report(*)
      raise NotImplementedError, UNSUPPORTED_MESSAGE
    end
  end
end
