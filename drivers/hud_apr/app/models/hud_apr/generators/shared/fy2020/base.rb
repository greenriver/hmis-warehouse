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
      @report.answer(question: self.class.question_number).update(error_messages: e.full_message)
      raise e
    end

    def self.most_recent_answer(user_id:)
      HudReports::ReportCell.universe.where(question: question_number).
        joins(:report_instance).
        merge(HudReports::ReportInstance.where(user_id: user_id)).
        order(created_at: :desc).
        first
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
      households[household_id].map { |dob| GrdaWarehouse::Hud::Client.age(date: date, dob: dob) }
    end

    private def households
      @households ||= {}.tap do |hh|
        enrollment_scope.where(client_id: @generator.client_scope.select(:id)).find_each do |enrollment|
          hh[enrollment.household_id] ||= []
          hh[enrollment.household_id] << enrollment.enrollment.client.DOB
        end
      end
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
  end
end
