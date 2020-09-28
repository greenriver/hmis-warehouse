###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class Base < HudReports::QuestionBase
    # DEV NOTES: These can be run like so:
    # options = {user_id: 1, coc_code: 'KY-500', start_date: '2018-10-01', end_date: '2019-09-30', project_ids: [1797], generator_class: 'HudApr::Generators::Apr::Fy2020::Generator'}
    # HudApr::Generators::Shared::Fy2020::QuestionFour.new(options: options).run!

    def run!
      run_question!
    rescue Exception => e
      @report.answer(question: self.class.question_number).update(error_messages: e.full_message, status: 'Failed')
      @report.update(state: 'Failed')
      raise e
    end

    def self.most_recent_answer(user:, report_name:)
      answer = HudReports::ReportCell.universe.where(question: question_number).
        joins(:report_instance).
        merge(HudReports::ReportInstance.where(report_name: report_name))
      answer = answer.merge(HudReports::ReportInstance.where(user_id: user.id)) unless user.can_view_all_hud_reports?
      answer.order(created_at: :desc).first
    end

    protected def build_universe(question_number, preloads: {}, before_block: nil, after_block: nil)
      universe_cell = @report.universe(question_number)

      @generator.client_scope.find_in_batches do |batch|
        pending_associations = {}

        clients_with_enrollments = clients_with_enrollments(batch, preloads: preloads)

        before_block.call(clients_with_enrollments) if before_block.present?

        batch.each do |client|
          pending_associations[client] = yield(client, clients_with_enrollments[client.id])
        end

        report_client_universe.import(
          pending_associations.values,
          on_duplicate_key_update: {
            conflict_target: [:client_id, :data_source_id, :report_instance_id],
            columns: pending_associations.values.first&.changes&.keys || [],
          },
        )

        after_block.call(clients_with_enrollments, pending_associations) if after_block.present?

        universe_cell.add_universe_members(pending_associations)
      end
      universe_cell
    end

    private def clients_with_enrollments(batch, preloads: {})
      enrollment_scope(preloads: preloads).where(client_id: batch.map(&:id)).group_by(&:client_id)
    end

    private def enrollment_scope(preloads: {})
      preloads = {
        enrollment: [
          :client,
          :disabilities,
          :current_living_situations,
          :project,
        ],
      }.deep_merge(preloads)
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        open_between(start_date: @report.start_date, end_date: @report.end_date).
        joins(:enrollment).
        preload(preloads)
      scope = scope.in_project(@report.project_ids) if @report.project_ids.present? # for consistency with client_scope
      scope
    end

    private def ages_for(household_id, date)
      households[household_id].map { |client| GrdaWarehouse::Hud::Client.age(date: date, dob: client[:dob]) }
    end

    private def households
      @households ||= {}.tap do |hh|
        enrollment_scope.where(client_id: @generator.client_scope.select(:id)).find_each do |enrollment|
          hh[enrollment.household_id] ||= []
          hh[enrollment.household_id] << {
            source_client_id: enrollment.enrollment.client.id,
            dob: enrollment.enrollment.client.DOB,
            veteran_status: enrollment.enrollment.client.VeteranStatus,
            chronic_status: enrollment.enrollment.chronically_homeless_at_start?,
            relationship_to_hoh: enrollment.enrollment.RelationshipToHoH,
          }
        end
      end
    end

    private def household_member_data(enrollment)
      return nil unless enrollment[:head_of_household]

      households[enrollment.household_id]
    end

    private def household_veterans_chronically_homeless?(apr_client)
      adults = household_adults(apr_client)
      veterans = household_veterans(adults)
      household_chronically_homeless_clients(veterans).any?
    end

    private def household_veterans_non_chronically_homeless?(apr_client)
      adults = household_adults(apr_client)
      veterans = household_veterans(adults)
      household_non_chronically_homeless_clients(veterans).any?
    end

    # Note, you need to pass in an apr client because the date needs to be calculated
    private def household_adults(apr_client)
      date = [apr_client.first_date_in_program, @report.start_date].max
      apr_client.household_members.select do |member|
        next false if member['dob'].blank?

        age = GrdaWarehouse::Hud::Client.age(date: date, dob: member['dob'].to_date)
        age.present? && age >= 18
      end
    end

    private def all_household_adults_veterans?(apr_client)
      household_adults(apr_client).all? do |member|
        member['veteran_status'] == 1
      end
    end

    private def all_household_adults_non_veterans?(apr_client)
      household_adults(apr_client).all? do |member|
        member['veteran_status'].zero?
      end
    end

    # accepts a household_members cell from apr_clients
    private def household_veterans(household_members)
      household_members.select do |member|
        member['veteran_status'] == 1
      end
    end

    private def household_non_veterans(household_members)
      household_members.select do |member|
        member['veteran_status'].zero?
      end
    end

    private def household_adults_refused_veterans(apr_client)
      household_adults(apr_client).select do |member|
        member['veteran_status'].in?([8, 9])
      end
    end

    private def household_adults_missing_veterans(apr_client)
      household_adults(apr_client).select do |member|
        member['veteran_status'] == 99
      end
    end

    private def household_chronically_homeless_clients(household_members)
      household_members.select do |member|
        member['chronic_status'] == true
      end
    end

    private def household_non_chronically_homeless_clients(household_members)
      household_members.select do |member|
        member['chronic_status'] == false
      end
    end

    private def only_youth?(apr_client)
      youth_household_members(apr_client).count == apr_client.household_members.count
    end

    private def youth_household_members(apr_client)
      date = [apr_client.first_date_in_program, @report.start_date].max
      apr_client.household_members.select do |member|
        next false if member['dob'].blank?

        age = GrdaWarehouse::Hud::Client.age(date: date, dob: member['dob'].to_date)
        age.present? && age >= 24
      end
    end

    private def youth_child_members(apr_client)
      youth_household_members(apr_client).select do |member|
        member['relationship_to_hoh'] == 2
      end
    end

    private def youth_children?(apr_client)
      youth_child_members(apr_client).any?
    end

    private def youth_child_source_client_ids(apr_client)
      youth_child_members(apr_client).map { |member| member['source_client_id'] }
    end

    private def adult_source_client_ids(apr_client)
      household_adults(apr_client).map { |member| member['source_client_id'] }
    end

    private def youth_parent?(apr_client)
      apr_client.head_of_household && only_youth?(apr_client) && youth_children?(apr_client)
    end

    private def report_client_universe
      HudApr::Fy2020::AprClient
    end

    private def report_living_situation_universe
      HudApr::Fy2020::AprLivingSituation
    end

    private def a_t
      @a_t ||= report_client_universe.arel_table
    end

    private def child_clause
      a_t[:age].between(0..17)
    end

    private def adult_clause
      a_t[:age].gteq(18)
    end

    private def hoh_clause
      a_t[:head_of_household].eq(true)
    end

    private def adult_or_hoh_clause
      adult_clause.or(hoh_clause)
    end

    private def veteran_clause
      adult_clause.and(a_t[:veteran_status].eq(1))
    end

    private def stayers_clause
      a_t[:last_date_in_program].eq(nil).or(a_t[:last_date_in_program].gt(@report.end_date))
    end

    private def leavers_clause
      a_t[:last_date_in_program].lteq(@report.end_date)
    end

    # Heads of Household who have been enrolled for at least 365 days
    private def hoh_lts_stayer_ids
      @hoh_lts_stayer_ids ||= universe.members.where(
        hoh_clause.
        and(a_t[:length_of_stay].gteq(365)).
        and(stayers_clause),
      ).pluck(:head_of_household_id)
    end

    private def hoh_exit_dates
      @hoh_exit_dates ||= universe.members.where(hoh_clause).pluck(a_t[:head_of_household_id], a_t[:last_date_in_program]).to_h
    end

    private def hoh_entry_dates
      @hoh_entry_dates ||= {}.tap do |entries|
        enrollment_scope.where(client_id: @generator.client_scope.select(:id)).heads_of_households.
          find_each do |enrollment|
            entries[enrollment[:head_of_household_id]] ||= enrollment.first_date_in_program
          end
      end
    end

    private def hoh_move_in_dates
      @hoh_move_in_dates ||= {}.tap do |entries|
        enrollment_scope.where(client_id: @generator.client_scope.select(:id)).heads_of_households.
          find_each do |enrollment|
            entries[enrollment[:head_of_household_id]] ||= enrollment.move_in_date
          end
      end
    end

    # Returns a sql query clause appropriate to see if a value exists or doesn't exist in a
    # jsonb hash
    # EX: 1 in (coalesce(data->>'a', '99'), coalesce(data->>'b', '99'))
    private def income_jsonb_clause(value, column, negation: false, coalesce_value: 99)
      if negation
        query = "'#{value}' not in ("
      else
        query = "'#{value}' in ("
      end
      measures = GrdaWarehouse::Hud::IncomeBenefit::SOURCES.keys.map do |income_measure|
        "coalesce(#{column}->>'#{income_measure}', '#{coalesce_value}')"
      end
      query += measures.join(', ') + ')'
      Arel.sql(query)
    end

    private def benefit_jsonb_clause(value, column, negation: false, coalesce_value: 99)
      if negation
        query = "'#{value}' not in ("
      else
        query = "'#{value}' in ("
      end
      measures = GrdaWarehouse::Hud::IncomeBenefit::NON_CASH_BENEFIT_TYPES.map do |measure|
        "coalesce(#{column}->>'#{measure}', '#{coalesce_value}')"
      end
      query += measures.join(', ') + ')'
      Arel.sql(query)
    end

    private def insurance_jsonb_clause(value, column, negation: false, coalesce_value: 99)
      if negation
        query = "'#{value}' not in ("
      else
        query = "'#{value}' in ("
      end
      measures = GrdaWarehouse::Hud::IncomeBenefit::INSURANCE_TYPES.map do |measure|
        "coalesce(#{column}->>'#{measure}', '#{coalesce_value}')"
      end
      query += measures.join(', ') + ')'
      Arel.sql(query)
    end

    private def age_ranges
      {
        'Under 5' => a_t[:age].between(0..4),
        '5-12' => a_t[:age].between(5..12),
        '13-17' => a_t[:age].between(13..17),
        '18-24' => a_t[:age].between(18..24),
        '25-34' => a_t[:age].between(25..34),
        '35-44' => a_t[:age].between(35..44),
        '45-54' => a_t[:age].between(45..54),
        '55-61' => a_t[:age].between(55..61),
        '62+' => a_t[:age].gteq(62),
        "Client Doesn't Know/Client Refused" => a_t[:dob_quality].in([8, 9]),
        'Data Not Collected' => a_t[:dob_quality].not_in([8, 9]).and(a_t[:dob_quality].eq(99).or(a_t[:dob_quality].eq(nil)).or(a_t[:age].lt(0)).or(a_t[:age].eq(nil))),
        'Total' => Arel.sql('1=1'), # include everyone
      }
    end

    private def sub_populations
      {
        'Total' => Arel.sql('1=1'), # include everyone
        'Without Children' => a_t[:household_type].eq(:adults_only),
        'With Children and Adults' => a_t[:household_type].eq(:adults_and_children),
        'With Only Children' => a_t[:household_type].eq(:children_only),
        'Unknown Household Type' => a_t[:household_type].eq(:unknown),
      }
    end

    # NOTE: HUD, in the APR specifies these by order ID
    # this practice is very brittle, so we'll copy those here and hard code those relationships
    private def races
      {
        'AmIndAKNative' => {
          order: 1,
          label: 'American Indian or Alaska Native',
          clause: a_t[:race].eq(race_number('AmIndAKNative')),
        },
        'Asian' => {
          order: 2,
          label: 'Asian',
          clause: a_t[:race].eq(race_number('Asian')),
        },
        'BlackAfAmerican' => {
          order: 3,
          label: 'Black or African American',
          clause: a_t[:race].eq(race_number('BlackAfAmerican')),
        },
        'NativeHIOtherPacific' => {
          order: 4,
          label: 'Native Hawaiian or Other Pacific Islander',
          clause: a_t[:race].eq(race_number('NativeHIOtherPacific')),
        },
        'White' => {
          order: 5,
          label: 'White',
          clause: a_t[:race].eq(race_number('White')),
        },
        'Multiple' => {
          order: 7,
          label: 'Multiple Races',
          clause: a_t[:race].eq(6),
        },
        'Unknown' => {
          order: 7,
          label: "Client Doesn't Know/Client Refused",
          clause: a_t[:race].in([8, 9]),
        },
        'Data Not Collected' => {
          order: 8,
          label: 'Data Not Collected',
          clause: a_t[:race].eq(99),
        },
        'Total' => {
          order: 9,
          label: 'Total',
          clause: Arel.sql('1=1'),
        },
      }.sort_by { |_, m| m[:order] }.freeze
    end

    private def race_fields
      {
        'AmIndAKNative' => 1,
        'Asian' => 2,
        'BlackAfAmerican' => 3,
        'NativeHIOtherPacific' => 4,
        'White' => 5,
      }.freeze
    end

    private def race_number(code)
      race_fields[code]
    end

    private def yes_know_dkn_clauses(column)
      {
        'Yes' => column.eq(1),
        'No' => column.eq(0),
        'Client Doesn’t Know/Client Refused' => column.in([8, 9]),
        'Data Not Collected' => column.eq(99).or(column.eq(nil)),
        'Total' => Arel.sql('1=1'),
      }
    end

    def calculate_race(client)
      return client.RaceNone if client.RaceNone.in?([8, 9, 99]) # bad data
      return 6 if client.race_fields.count > 1 # multi-racial
      return 99 if client.race_fields.empty?

      race_number(client.race_fields.first) # return the HUD numeral equivalent
    end

    private def ethnicities
      {
        '0' => {
          order: 1,
          label: 'Non-Hispanic/Non-Latino',
          clause: a_t[:ethnicity].eq(0),
        },
        '1' => {
          order: 2,
          label: 'Hispanic/Latino',
          clause: a_t[:ethnicity].eq(1),
        },
        '8 or 9' => {
          order: 3,
          label: 'Client Doesn’t Know/Client Refused',
          clause: a_t[:ethnicity].in([8, 9]),
        },
        '99' => {
          order: 4,
          label: 'Data Not Collected',
          clause: a_t[:ethnicity].eq(99).or(a_t[:ethnicity].eq(nil)),
        },
        'Total' => {
          order: 5,
          label: 'Total',
          clause: Arel.sql('1=1'),
        },
      }.sort_by { |_, m| m[:order] }.freeze
    end

    private def living_situations
      {
        'Homeless Situations' => nil,
        'Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or RHY-funded Host Home shelter' => a_t[:prior_living_situation].eq(1),
        'Transitional housing for homeless persons (including homeless youth)' => a_t[:prior_living_situation].eq(2),
        'Place not meant for habitation' => a_t[:prior_living_situation].eq(16),
        'Safe Haven' => a_t[:prior_living_situation].eq(18),
        'Host Home (non-crisis)' => a_t[:prior_living_situation].eq(32),
        'Subtotal - Homeless' => a_t[:prior_living_situation].in([1, 2, 16, 18, 32]),
        'Institutional Settings' => nil,
        'Psychiatric hospital or other psychiatric facility' => a_t[:prior_living_situation].eq(4),
        'Substance abuse treatment facility or detox center' => a_t[:prior_living_situation].eq(5),
        'Hospital or other residential non-psychiatric medical facility' => a_t[:prior_living_situation].eq(6),
        'Jail, prison or juvenile detention facility' => a_t[:prior_living_situation].eq(7),
        'Foster care home or foster care group home' => a_t[:prior_living_situation].eq(15),
        'Long-term care facility or nursing home' => a_t[:prior_living_situation].eq(25),
        'Residential project or halfway house with no homeless criteria' => a_t[:prior_living_situation].eq(29),
        'Subtotal - Institutional' => a_t[:prior_living_situation].in([4, 5, 6, 7, 15, 25, 29]),
        'Other Locations' => nil,
        'Permanent housing (other than RRH) for formerly homeless persons' => a_t[:prior_living_situation].eq(3),
        'Owned by client, no ongoing housing subsidy' => a_t[:prior_living_situation].eq(11),
        'Owned by client, with ongoing housing subsidy' => a_t[:prior_living_situation].eq(21),
        'Rental by client, with RRH or equivalent subsidy' => a_t[:prior_living_situation].eq(31),
        'Rental by client, with HCV voucher (tenant or project based)' => a_t[:prior_living_situation].eq(33),
        'Rental by client in a public housing unit' => a_t[:prior_living_situation].eq(34),
        'Rental by client, no ongoing housing subsidy' => a_t[:prior_living_situation].eq(10),
        'Rental by client, with VASH housing subsidy' => a_t[:prior_living_situation].eq(19),
        'Rental by client, with GPD TIP housing subsidy' => a_t[:prior_living_situation].eq(28),
        'Rental by client, with other ongoing housing subsidy' => a_t[:prior_living_situation].eq(20),
        'Hotel or motel paid for without emergency shelter voucher' => a_t[:prior_living_situation].eq(14),
        "Staying or living in a friend's room, apartment or house" => a_t[:prior_living_situation].eq(36),
        "Staying or living in a family member's room, apartment or house" => a_t[:prior_living_situation].eq(35),
        'Client Doesn’t Know/Client Refused' => a_t[:prior_living_situation].in([8, 9]),
        'Data Not Collected' => a_t[:prior_living_situation].eq(99).or(a_t[:prior_living_situation].eq(nil)),
        'Subtotal - Other' => a_t[:prior_living_situation].in(
          [
            3,
            11,
            21,
            31,
            33,
            34,
            10,
            19,
            28,
            20,
            14,
            36,
            35,
            8,
            9,
            99,
          ],
        ).or(a_t[:prior_living_situation].eq(nil)),
        'Total' => Arel.sql('1=1'),
      }
    end

    private def household_makeup(household_id, date)
      return :adults_and_children if adults?(ages_for(household_id, date)) && children?(ages_for(household_id, date))
      return :adults_only if adults?(ages_for(household_id, date)) && ! children?(ages_for(household_id, date)) && ! unknown_ages?(ages_for(household_id, date))
      return :children_only if children?(ages_for(household_id, date)) && ! adults?(ages_for(household_id, date)) && ! unknown_ages?(ages_for(household_id, date))

      :unknown
    end

    private def adults?(ages)
      ages.any? do |age|
        next false if age.blank?

        age >= 18
      end
    end

    private def children?(ages)
      ages.any? do |age|
        next false if age.blank?

        age < 18
      end
    end

    private def unknown_ages?(ages)
      ages.any? do |age|
        next true if age.blank?
        next true if age < 1

        false
      end
    end

    # Given the reporting period, how long has the client been in the enrollment
    private def stay_length(enrollment)
      end_date = [
        enrollment.last_date_in_program,
        @report.end_date + 1.day,
      ].compact.min
      (end_date - enrollment.first_date_in_program).to_i
    end

    private def time_to_move_in(enrollment)
      move_in_date = appropriate_move_in_date(enrollment)
      return nil unless move_in_date.present?

      (move_in_date - enrollment.first_date_in_program).to_i
    end

    private def approximate_time_to_move_in(enrollment)
      move_in_date = if enrollment.computed_project_type.in?(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph])
        appropriate_move_in_date(enrollment) || enrollment.first_date_in_program
      else
        enrollment.first_date_in_program
      end
      date_to_street = enrollment.enrollment.DateToStreetESSH
      return nil if date_to_street.blank? || date_to_street > move_in_date

      (move_in_date - date_to_street).to_i
    end

    # Household members already in the household when the head of household moves into housing have the same [housing move-in date] as the head of household. For household members joining the household after it is already in housing, use the person’s [project start date] as their [housing move-in date].
    private def appropriate_move_in_date(enrollment)
      # Use the move-in-date if provided
      move_in_date = enrollment.move_in_date
      return move_in_date if move_in_date.present?

      hoh_move_in_date = hoh_entry_dates[enrollment[:head_of_household]]
      return nil unless hoh_move_in_date.present?
      return hoh_move_in_date if enrollment.first_date_in_program < hoh_move_in_date

      enrollment.first_date_in_program
    end

    private def annual_assessment(enrollment)
      enrollment.income_benefits_annual_update.select do |i|
        i.InformationDate < @report.end_date
      end.max_by(&:InformationDate)
    end

    private def income_sources(income)
      sources = GrdaWarehouse::Hud::IncomeBenefit::SOURCES.keys.map(&:to_s)
      sources += GrdaWarehouse::Hud::IncomeBenefit::NON_CASH_BENEFIT_TYPES.map(&:to_s)
      sources += GrdaWarehouse::Hud::IncomeBenefit::INSURANCE_TYPES.map(&:to_s)
      amounts = GrdaWarehouse::Hud::IncomeBenefit::SOURCES.values.map(&:to_s)
      income&.attributes&.slice(*(sources + amounts)) || sources.map { |k| [k, 99] }.to_h.merge(amounts.map { |k| [k, nil] }.to_h)
    end

    private def annual_assessment_expected?(enrollment)
      elapsed_years = @report.end_date.year - enrollment.first_date_in_program.year
      elapsed_years -= 1 if enrollment.first_date_in_program + elapsed_years.year > @report.end_date
      enrollment.head_of_household? && elapsed_years&.positive?
    end

    private def earned_amount(apr_client, suffix)
      apr_client["income_sources_at_#{suffix}"]['EarnedAmount']
    end

    private def other_amount(apr_client, suffix)
      total_amount = total_amount(apr_client, suffix)
      return 0 unless total_amount.present? && total_amount.positive?

      earned = earned_amount(apr_client, suffix).presence || 0
      total_amount.to_i - earned.to_i
    end

    private def total_amount(apr_client, suffix)
      apr_client["income_total_at_#{suffix}"]
    end

    # We have earned income if we said we had earned income and the amount is positive
    private def earned_income?(apr_client, suffix)
      return false unless apr_client["income_sources_at_#{suffix}"]['Earned'] == 1

      earned_amt = earned_amount(apr_client, suffix)
      return false unless earned_amt.blank?

      earned_amt.positive?
    end

    # We have other income if the total is positive and not equal to the earned amount
    private def other_income?(apr_client, suffix)
      total_amount = total_amount(apr_client, suffix)
      return false unless total_amount.present? && total_amount.positive?

      total_amount != earned_amount(apr_client, suffix)
    end

    private def total_income?(apr_client, suffix)
      total_amount = total_amount(apr_client, suffix)
      total_amount.present? && total_amount.positive?
    end

    private def income_for_category?(apr_client, category:, suffix:)
      case category
      when :earned
        earned_income?(apr_client, suffix)
      when :other
        other_income?(apr_client, suffix)
      when :total
        total_income?(apr_client, suffix)
      end
    end

    private def both_income_types?(apr_client, suffix)
      earned_income?(apr_client, suffix) && other_income?(apr_client, suffix)
    end

    private def no_income?(apr_client, suffix)
      [
        earned_income?(apr_client, suffix),
        other_income?(apr_client, suffix),
      ].none?
    end

    private def income_change(apr_client, category:, initial:, subsequent:)
      case category
      when :total
        initial_amount = apr_client["income_total_at_#{initial}"]
        subsequent_amount = apr_client["income_total_at_#{subsequent}"]
      when :earned
        initial_amount = earned_amount(apr_client, initial)
        subsequent_amount = earned_amount(apr_client, subsequent)
      when :other
        initial_amount = other_amount(apr_client, initial)
        subsequent_amount = other_amount(apr_client, subsequent)
      end
      return unless initial_amount && subsequent_amount

      subsequent_amount.to_f - initial_amount.to_f
    end

    private def disability_clauses(suffix)
      {
        'Mental Health Problem' => a_t["mental_health_problem_#{suffix}".to_sym].eq(1),
        'Alcohol Abuse' => a_t["alcohol_abuse_#{suffix}".to_sym].eq(true),
        'Drug Abuse' => a_t["drug_abuse_#{suffix}".to_sym].eq(true),
        'Both Alcohol and Drug Abuse' => a_t["alcohol_abuse_#{suffix}".to_sym].eq(true).
          and(a_t["drug_abuse_#{suffix}".to_sym].eq(true)),
        'Chronic Health Condition' => a_t["chronic_disability_#{suffix}".to_sym].eq(1),
        'HIV/AIDS' => a_t["hiv_aids_#{suffix}".to_sym].eq(1),
        'Developmental Disability' => a_t["developmental_disability_#{suffix}".to_sym].eq(1),
        'Physical Disability' => a_t["physical_disability_#{suffix}".to_sym].eq(1),
      }
    end

    private def lengths
      {
        '0 to 7 days' => a_t[:length_of_stay].between(0..7),
        '8 to 14 days' => a_t[:length_of_stay].between(8..14),
        '15 to 21 days' => a_t[:length_of_stay].between(15..21),
        '22 to 30 days' => a_t[:length_of_stay].between(22..30),
        '30 days or less' => a_t[:length_of_stay].lteq(30),
        '31 to 60 days' => a_t[:length_of_stay].between(31..60),
        '61 to 90 days' => a_t[:length_of_stay].between(61..90),
        '61 to 180 days' => a_t[:length_of_stay].between(61..180),
        '91 to 180 days' => a_t[:length_of_stay].between(91..180),
        '181 to 365 days' => a_t[:length_of_stay].between(181..365),
        '366 to 730 days (1-2 Yrs)' => a_t[:length_of_stay].between(366..730),
        '731 to 1,095 days (2-3 Yrs)' => a_t[:length_of_stay].between(731..1_095),
        '731 days or more' => a_t[:length_of_stay].gteq(731),
        '1,096 to 1,460 days (3-4 Yrs)' => a_t[:length_of_stay].between(1_096..1_460),
        '1,461 to 1,825 days (4-5 Yrs)' => a_t[:length_of_stay].between(1_461..1_825),
        'More than 1,825 days (> 5 Yrs)' => a_t[:length_of_stay].gteq(1_825),
        'Data Not Collected' => a_t[:length_of_stay].eq(nil),
        'Total' => Arel.sql('1=1'),
      }.freeze
    end

    private def income_responses(suffix)
      {
        'Adults with Only Earned Income (i.e., Employment Income)' => :earned,
        'Adults with Only Other Income' => :other,
        'Adults with Both Earned and Other Income' => :both,
        'Adults with No Income' => :none,
        'Adults with Client Doesn’t Know/Client Refused Income Information' => a_t["income_from_any_source_at_#{suffix}"].in([8, 9]),
        'Adults with Missing Income Information' => a_t["income_from_any_source_at_#{suffix}"].eq(99).
          or(a_t["income_from_any_source_at_#{suffix}"].eq(nil)).
          and(a_t["income_sources_at_#{suffix}"].not_eq(nil)),
        'Number of adult stayers not yet required to have an annual assessment' => adult_clause.
          and(stayers_clause).
          and(a_t[:annual_assessment_expected].eq(false)),
        'Number of adult stayers without required annual assessment' => adult_clause.
          and(stayers_clause).
          and(a_t[:annual_assessment_expected].eq(true)).
          and(a_t[:income_from_any_source_at_annual_assessment].eq(nil)),
        'Total Adults' => Arel.sql('1=1'),
        '1 or more source of income' => a_t["income_total_at_#{suffix}"].gt(0),
        'Adults with Income Information at Start and Annual Assessment/Exit' => a_t['income_from_any_source_at_start'].in([0, 1]).and(a_t["income_from_any_source_at_#{suffix}"].in([0, 1])),
      }
    end

    private def income_types(suffix)
      {
        'Earned Income' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { Earned: 1 } } },
        'Unemployment Insurance' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { Unemployment: 1 } } },
        'Supplemental Security Income (SSI)' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { SSI: 1 } } },
        'Social Security Disability Insurance (SSDI)' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { SSDI: 1 } } },
        'VA Service – Connected Disability Compensation' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { VADisabilityService: 1 } } },
        'VA Non-Service Connected Disability Pension' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { VADisabilityNonService: 1 } } },
        'Private Disability Insurance' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { PrivateDisability: 1 } } },
        "Worker's Compensation" => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { WorkersComp: 1 } } },
        'Temporary Assistance for Needy Families (TANF)' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { TANF: 1 } } },
        'General Assistance (GA)' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { GA: 1 } } },
        'Retirement Income from Social Security' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { SocSecRetirement: 1 } } },
        'Pension or retirement income from a former job' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { Pension: 1 } } },
        'Child Support' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { ChildSupport: 1 } } },
        'Alimony and other spousal support' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { Alimony: 1 } } },
        'Other Source' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { OtherIncomeSource: 1 } } },
        'Adults with Income Information at Start and Annual Assessment/Exit' => a_t['income_from_any_source_at_start'].in([0, 1]).and(a_t["income_from_any_source_at_#{suffix}"].in([0, 1])),
      }
    end

    private def non_cash_benefit_types(suffix)
      {
        'Supplemental Nutrition Assistance Program (SNAP) (Previously known as Food Stamps)' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { SNAP: 1 } } },
        'Special Supplemental Nutrition Program for Women, Infants, and Children (WIC)' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { WIC: 1 } } },
        'TANF Child Care Services' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { TANFChildCare: 1 } } },
        'TANF Transportation Services' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { TANFTransportation: 1 } } },
        'Other TANF-Funded Services' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { OtherTANF: 1 } } },
        'Other Source' => { hud_report_apr_clients: { "income_sources_at_#{suffix}" => { OtherBenefitsSource: 1 } } },
      }
    end

    private def destination_clauses
      {
        'Permanent Destinations' => nil,
        'Moved from one HOPWA funded project to HOPWA PH' => a_t[:destination].eq(26),
        'Owned by client, no ongoing housing subsidy' => a_t[:destination].eq(11),
        'Owned by client, with ongoing housing subsidy' => a_t[:destination].eq(21),
        'Rental by client, no ongoing housing subsidy' => a_t[:destination].eq(10),
        'Rental by client, with VASH housing subsidy' => a_t[:destination].eq(19),
        'Rental by client, with GPD TIP housing subsidy' => a_t[:destination].eq(28),
        'Rental by client, with other ongoing housing subsidy' => a_t[:destination].eq(20),
        'Permanent housing (other than RRH) for formerly homeless persons' => a_t[:destination].eq(3),
        'Staying or living with family, permanent tenure' => a_t[:destination].eq(22),
        'Staying or living with friends, permanent tenure' => a_t[:destination].eq(23),
        'Rental by client, with RRH or equivalent subsidy' => a_t[:destination].eq(31),
        'Rental by client, with HCV voucher (tenant or project based)' => a_t[:destination].eq(33),
        'Rental by client in a public housing unit' => a_t[:destination].eq(34),
        'Subtotal - Permanent' => a_t[:destination].in([26, 11, 21, 10, 19, 28, 20, 3, 22, 23, 31, 33, 34]),
        'Temporary Destinations' => nil,
        'Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or RHY-funded Host Home shelter' => a_t[:destination].eq(1),
        'Moved from one HOPWA funded project to HOPWA TH' => a_t[:destination].eq(27),
        'Transitional housing for homeless persons (including homeless youth)' => a_t[:destination].eq(2),
        'Staying or living with family, temporary tenure (e.g. room, apartment or house)' => a_t[:destination].eq(12),
        'Staying or living with friends, temporary tenure (e.g. room, apartment or house)' => a_t[:destination].eq(13),
        'Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)' => a_t[:destination].eq(16),
        'Safe Haven' => a_t[:destination].eq(18),
        'Hotel or motel paid for without emergency shelter voucher' => a_t[:destination].eq(14),
        'Host Home (non-crisis)' => a_t[:destination].eq(32),
        'Subtotal - Temporary' => a_t[:destination].in([1, 27, 2, 12, 13, 16, 18, 14, 32]),
        'Institutional Settings' => nil,
        'Foster care home or group foster care home' => a_t[:destination].eq(15),
        'Psychiatric hospital or other psychiatric facility' => a_t[:destination].eq(4),
        'Substance abuse treatment facility or detox center' => a_t[:destination].eq(5),
        'Hospital or other residential non-psychiatric medical facility' => a_t[:destination].eq(6),
        'Jail, prison, or juvenile detention facility' => a_t[:destination].eq(7),
        'Long-term care facility or nursing home' => a_t[:destination].eq(25),
        'Subtotal - Institutional' => a_t[:destination].in([15, 4, 5, 6, 7, 25]),
        'Other Destinations' => nil,
        'Residential project or halfway house with no homeless criteria' => a_t[:destination].eq(29),
        'Deceased' => a_t[:destination].eq(24),
        'Other' => a_t[:destination].eq(17),
        "Client Doesn't Know/Client Refused" => a_t[:destination].in([8, 9]),
        'Data Not Collected (no exit interview completed)' => a_t[:destination].in([30, 99]),
        'Subtotal - Other' => a_t[:destination].in([29, 24, 17, 8, 9, 30, 99]),
        'Total' => leavers_clause,
        'Total persons exiting to positive housing destinations' => a_t[:project_type].in([1, 2]).
          and(a_t[:destination].in(positive_destinations(1))).
          or(a_t[:project_type].eq(4).and(a_t[:destination].in(positive_destinations(4)))).
          or(a_t[:project_type].not_in([1, 2, 4]).and(a_t[:destination].in(positive_destinations(8)))),
        'Total persons whose destinations excluded them from the calculation' => a_t[:project_type].not_eq(4).
          and(a_t[:destination].in(excluded_destinations(1))).
          or(a_t[:project_type].eq(4).and(a_t[:destination].in(excluded_destinations(4)))),
        'Percentage' => :percentage,
      }.freeze
    end

    private def positive_destinations(project_type)
      case project_type
      when 4
        [1, 15, 14, 27, 4, 18, 12, 13, 5, 2, 25, 32, 26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34]
      when 1, 2
        [32, 26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34]
      else
        [26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34]
      end
    end

    private def excluded_destinations(project_type)
      case project_type
      when 4
        [6, 29, 24]
      else
        [15, 6, 25, 24]
      end
    end
  end
end
