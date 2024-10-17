###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024::Dq::QuestionFive
  extend ActiveSupport::Concern

  included do
    private def generate_q5(table_name)
      metadata = {
        header_row: [
          'Entering into project type',
          'Count of total records',
          'Missing time in institution (3.917.2)',
          'Missing time in housing (3.917.2)',
          'Approximate date this episode started (3.917.3) DK/PNTA/missing',
          'Number of times (3.917.4) DK/PNTA/missing',
          'Number of months (3.917.5) DK/PNTA/missing',
          '% of records unable to calculate',
        ],
        row_labels: [
          'ES-EE, ES-NbN, SH, Street Outreach',
          'TH',
          'PH (all)',
          'CE',
          'SSO, Day Shelter, HP',
          'Total',
        ],
        first_column: 'B',
        last_column: 'H',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      es_sh_so_projects = HudUtility2024.performance_reporting[:es] + HudUtility2024.performance_reporting[:sh] + HudUtility2024.performance_reporting[:so]
      th_projects = HudUtility2024.performance_reporting[:th]
      ph_projects = HudUtility2024.performance_reporting[:ph]
      ce_projects = HudUtility2024.performance_reporting[:ce]
      sso_ds_hp_projects = HudUtility2024.performance_reporting[:services_only] + HudUtility2024.performance_reporting[:day_shelter] + HudUtility2024.performance_reporting[:prevention]
      report_projects = es_sh_so_projects + th_projects + ph_projects + ce_projects + sso_ds_hp_projects

      adults_and_hohs = universe.members.where(engaged_clause).where(
        a_t[:project_type].in(report_projects).
          and(a_t[:first_date_in_program].gt(Date.parse('2016-10-01')).
            and(a_t[:age].gteq(18).
              or(a_t[:head_of_household].eq(true).
                and(a_t[:age].lt(18).
                  or(a_t[:age].eq(nil)))))),
      )

      es_sh_so_clients = es_sh_so(table_name, adults_and_hohs)
      th_clients = project_type_row(table_name, adults_and_hohs, row_number: 3, project_types: th_projects)
      ph_clients = project_type_row(table_name, adults_and_hohs, row_number: 4, project_types: ph_projects)
      ce_clients = project_type_row(table_name, adults_and_hohs, row_number: 5, project_types: ce_projects)
      sso_ds_hp_clients = project_type_row(table_name, adults_and_hohs, row_number: 6, project_types: sso_ds_hp_projects)

      # totals
      answer = @report.answer(question: table_name, cell: 'B7')
      answer.add_members(adults_and_hohs)
      answer.update(summary: adults_and_hohs.count)

      # percent
      answer = @report.answer(question: table_name, cell: 'H7')
      total_members = es_sh_so_clients.
        or(th_clients).
        or(ph_clients).
        or(ce_clients).
        or(sso_ds_hp_clients)
      answer.add_members(total_members)
      answer.update(summary: total_members.count)
      answer.update(summary: percentage(total_members.count / adults_and_hohs.count.to_f))
    end

    private def es_sh_so(table_name, adults_and_hohs)
      es_sh_so_projects = HudUtility2024.performance_reporting[:es] + HudUtility2024.performance_reporting[:sh] + HudUtility2024.performance_reporting[:so]
      es_sh_so = adults_and_hohs.where(a_t[:project_type].in(es_sh_so_projects))

      # count
      answer = @report.answer(question: table_name, cell: 'B2')
      members = es_sh_so
      answer.add_members(members)
      answer.update(summary: members.count)

      # date homeless missing
      answer = @report.answer(question: table_name, cell: 'E2')
      date_homeless_members = es_sh_so.where(a_t[:date_homeless].eq(nil))
      answer.add_members(date_homeless_members)
      answer.update(summary: date_homeless_members.count)

      # times homeless dk/r/missing
      answer = @report.answer(question: table_name, cell: 'F2')
      times_homeless_members = es_sh_so.where(
        a_t[:times_homeless].in([8, 9, 99]).
          or(a_t[:times_homeless].eq(nil)),
      )
      answer.add_members(times_homeless_members)
      answer.update(summary: times_homeless_members.count)

      # months homeless dk/r/missing
      answer = @report.answer(question: table_name, cell: 'G2')
      months_homeless_members = es_sh_so.where(
        a_t[:months_homeless].in([8, 9, 99]).
          or(a_t[:months_homeless].eq(nil)),
      )
      answer.add_members(months_homeless_members)
      answer.update(summary: months_homeless_members.count)

      # percent
      answer = @report.answer(question: table_name, cell: 'H2')
      members = date_homeless_members.
        or(times_homeless_members).
        or(months_homeless_members)
      answer.add_members(members)
      answer.update(summary: percentage(members.count / es_sh_so.count.to_f))

      members
    end

    private def project_type_row(table_name, adults_and_hohs, row_number:, project_types:)
      scope = adults_and_hohs.where(a_t[:project_type].in(project_types))
      buckets = [
        # count
        {
          cell: "B#{row_number}",
          clause: Arel.sql('1=1'),
          include_in_percent: false,
        },
        # missing time in institution
        {
          cell: "C#{row_number}",
          clause: a_t[:prior_living_situation].in((200..299).to_a).
            and(a_t[:prior_length_of_stay].in([8, 9, 99]).
              or(a_t[:prior_length_of_stay].eq(nil))),
          include_in_percent: true,
        },
        # missing time in housing
        {
          cell: "D#{row_number}",
          clause: a_t[:prior_living_situation].in((0..99).to_a + (300..499).to_a).
            or(a_t[:prior_living_situation].eq(nil)).
            and(a_t[:prior_length_of_stay].in([8, 9, 99]).
              or(a_t[:prior_length_of_stay].eq(nil))),
          include_in_percent: true,
        },
        # date homeless missing
        {
          cell: "E#{row_number}",
          clause: residence_restriction.and(a_t[:date_homeless].eq(nil)),
          include_in_percent: true,
        },
        # times homeless dk/r/missing
        {
          cell: "F#{row_number}",
          clause: residence_restriction.and(
            a_t[:times_homeless].in([8, 9, 99]).
            or(a_t[:times_homeless].eq(nil)),
          ),
          include_in_percent: true,
        },
        # months homeless dk/r/missing
        {
          cell: "G#{row_number}",
          clause: residence_restriction.and(
            a_t[:months_homeless].in([8, 9, 99]).
            or(a_t[:months_homeless].eq(nil)),
          ),
          include_in_percent: true,
        },
      ]
      buckets.each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = scope.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      # percent
      answer = @report.answer(question: table_name, cell: "H#{row_number}")
      ors = buckets.select { |m| m[:include_in_percent] }.map do |cell|
        "(#{cell[:clause].to_sql})"
      end
      members = scope.where(Arel.sql(ors.join(' or ')))
      answer.add_members(members)
      answer.update(summary: percentage(members.count / scope.count.to_f))

      members
    end

    private def residence_restriction
      @residence_restriction ||= a_t[:prior_living_situation].in((100..199).to_a).
        or(
          a_t[:prior_living_situation].in((200..299).to_a).
            and(a_t[:prior_length_of_stay].in([10, 11, 2, 3])).
            and(a_t[:came_from_street_last_night].eq(1)),
        ).
        or(
          a_t[:prior_living_situation].in((0..99).to_a + (300..499).to_a).
            or(a_t[:prior_living_situation].eq(nil)).
            and(a_t[:prior_length_of_stay].in([10, 11])).
            and(a_t[:came_from_street_last_night].eq(1)),
        )
    end
  end
end
