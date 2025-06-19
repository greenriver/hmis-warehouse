###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2026::Dq::QuestionSeven
  extend ActiveSupport::Concern

  included do
    private def generate_q7(table_name)
      metadata = {
        header_row: [
          'Data Element',
          '# of Records',
          '# of Inactive Records',
          '# % of Inactive Records',
        ],
        row_labels: [
          'Contact (Adults and Heads of Household in Street Outreach or PATH-funded SSO)',
        ],
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 3,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # Clients whose enrollment date is more than 90 days before the end of the report, and are still
      # enrolled until after the reporting period
      relevant_clients = universe.universe_members.joins(:apr_client).
        joins(report_cell: :report_instance).
        where(
          datediff(report_client_universe, 'day', hr_ri_t[:end_date], a_t[:first_date_in_program]).gteq(90).
            and(
              a_t[:last_date_in_program].eq(nil).
                or(a_t[:last_date_in_program].gt(@report.end_date)),
            ),
        )

      # Row 2 reports on adults and heads of household active in project type 4 (for all funding sources) and project type 6 if PATH-funded
      answer = @report.answer(question: table_name, cell: 'B2')
      adults_and_hohs = relevant_clients.where(adult_or_hoh_clause)

      # PATH funded project_ids
      path_funded_project_ids = GrdaWarehouse::Hud::Project.where(id: @report.project_ids).
        joins(:funders).
        merge(GrdaWarehouse::Hud::Funder.where(Funder: 21)).
        pluck(:id)

      query = a_t[:project_type].eq(4).
        and(a_t[:date_of_engagement].lt(@report.end_date))
      query = query.or(a_t[:project_type].eq(6).and(a_t[:project_id].in(path_funded_project_ids))) if path_funded_project_ids.present?
      so_or_path_funded_sso_members = adults_and_hohs.where(query)
      answer.add_members(so_or_path_funded_sso_members)
      answer.update(summary: so_or_path_funded_sso_members.count)

      # Inactive SO or PATH SSO
      answer = @report.answer(question: table_name, cell: 'C2')

      # inactive_so_or_path_funded_sso_members is based on ids so that 'or' works.
      inactive_so_or_path_funded_sso_member_ids = []
      so_or_path_funded_sso_members.find_each do |member|
        first_date_in_program = member.universe_membership.first_date_in_program
        next if first_date_in_program > @report.end_date - 90.days # Less than 90 days in report period

        last_current_living_situation = [
          member.universe_membership.hud_report_apr_living_situations.maximum(:information_date),
          first_date_in_program,
        ].compact.max
        inactive_so_or_path_funded_sso_member_ids << member.id if (@report.end_date - last_current_living_situation).to_i > 90
      end

      inactive_so_or_path_funded_sso_members = so_or_path_funded_sso_members.where(id: inactive_so_or_path_funded_sso_member_ids)
      answer.add_members(inactive_so_or_path_funded_sso_members)
      answer.update(summary: inactive_so_or_path_funded_sso_members.count)

      # percent inactive SO or PATH SSO
      answer = @report.answer(question: table_name, cell: 'D2')
      answer.add_members(inactive_so_or_path_funded_sso_members)
      answer.update(summary: percentage(inactive_so_or_path_funded_sso_members.count / so_or_path_funded_sso_members.count.to_f))

      # Relevant ES-NBN
      answer = @report.answer(question: table_name, cell: 'B3')
      es_members = relevant_clients.where(
        a_t[:project_type].eq(1),
      )
      answer.add_members(es_members)
      answer.update(summary: es_members.count)

      # Inactive ES
      answer = @report.answer(question: table_name, cell: 'C3')
      inactive_es_members = es_members.where(
        datediff(report_client_universe, 'day', hr_ri_t[:end_date], a_t[:date_of_last_bed_night]).gt(90),
      )
      answer.add_members(inactive_es_members)
      answer.update(summary: inactive_es_members.count)

      # percent inactive ES
      answer = @report.answer(question: table_name, cell: 'D3')
      answer.add_members(so_or_path_funded_sso_members)
      answer.update(summary: percentage(inactive_es_members.count / es_members.count.to_f))
    end
  end
end
