###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2021
  class QuestionTwentyOne < Base
    QUESTION_NUMBER = 'Question 21'.freeze

    def self.table_descriptions
      {
        'Question 21' => 'Health Insurance',
      }.freeze
    end

    private def q21_health_insurance
      table_name = 'Q21'
      metadata = {
        header_row: [' '] + health_insurance_stage.keys,
        row_labels: health_insurance_counts(:start).keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 17,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      health_insurance_stage.values.each_with_index do |stage, col_index|
        suffix = stage[:stage]
        stage_clause = stage[:clause]
        health_insurance_counts(suffix).values.each_with_index do |income_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(stage_clause)
          members = members.where(a_t[:annual_assessment_expected].eq(true)) if cell == 'C14' # Only count data not collected for clients who won't show in C15

          answer.update(summary: 0) and next if members.count.zero?

          if income_clause.is_a?(Hash)
            members = members.where.contains(income_clause)
          elsif income_clause.is_a?(Symbol)
            ids = Set.new
            sources = GrdaWarehouse::Hud::IncomeBenefit::INSURANCE_TYPES.map(&:to_s)
            members.preload(:universe_membership).find_each do |member|
              apr_client = member.universe_membership
              case income_clause
              when :one
                ids << member.id if apr_client["income_sources_at_#{suffix}"].values_at(*sources).count(1) == 1
              when :more_than_one
                ids << member.id if apr_client["income_sources_at_#{suffix}"].values_at(*sources).count(1) > 1
              end
            end
            members = members.where(id: ids)
          else
            members = members.where(income_clause)
          end
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def health_insurance_stage
      {
        'At Start' => {
          stage: :start,
          clause: Arel.sql('1=1'),
        },
        'At Annual Assessment for Stayers' => {
          stage: :annual_assessment,
          clause: stayers_clause,
        },
        'At Exit for Leavers' => {
          stage: :exit,
          clause: leavers_clause,
        },
      }
    end

    private def health_insurance_counts(suffix)
      {
        'MEDICAID' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { Medicaid: 1 } } },
        'MEDICARE' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { Medicare: 1 } } },
        "State Children's Health Insurance Program" => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { SCHIP: 1 } } },
        "Veteran's Administration (VA) Medical Services" => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { VAMedicalServices: 1 } } },
        'Employer – Provided Health Insurances' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { EmployerProvided: 1 } } },
        'Health Insurance obtained through COBRA' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { COBRA: 1 } } },
        'Private Pay Health Insurance' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { PrivatePay: 1 } } },
        'State Health Insurance for Adults' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { StateHealthIns: 1 } } },
        'Indian Health Services Program' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { IndianHealthServices: 1 } } },
        'Other' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { OtherInsurance: 1 } } },

        'No Health Insurance' => a_t["insurance_from_any_source_at_#{suffix}"].in([0, 1]).
          and(insurance_jsonb_clause(1, a_t["income_sources_at_#{suffix}"].to_sql, negation: true)).
          and(insurance_jsonb_clause(99, a_t["income_sources_at_#{suffix}"].to_sql, negation: true)),
        "Client Doesn't Know/Client Refused" => a_t["insurance_from_any_source_at_#{suffix}"].in([8, 9]).
          and(insurance_jsonb_clause(1, a_t["income_sources_at_#{suffix}"].to_sql, negation: true)),
        'Data not Collected' => a_t["insurance_from_any_source_at_#{suffix}"].eq(99).
          or(a_t["insurance_from_any_source_at_#{suffix}"].eq(nil)).
          and(insurance_jsonb_clause(1, a_t["income_sources_at_#{suffix}"].to_sql, negation: true)),
        'Number of Stayers not yet Required To Have an Annual Assessment' => a_t[:annual_assessment_expected].eq(false).
          and(a_t[:head_of_household].eq(true)), # Annual assessments are only expected for HoHs
        '1 Source of Health Insurance' => :one,
        'More than 1 Source of Health Insurance' => :more_than_one,
      }
    end

    private def intentionally_blank
      [
        'B15',
        'D15',
      ].freeze
    end
  end
end
