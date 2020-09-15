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

    protected def build_universe(question_number, before_block: nil, after_block: nil)
      universe_cell = @report.universe(question_number)

      @generator.client_scope.find_in_batches do |batch|
        pending_associations = {}

        clients_with_enrollments = clients_with_enrollments(batch)

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

    protected def clients_with_enrollments(batch)
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        joins(:enrollment).
        preload(enrollment: [:client, :disabilities, :current_living_situations, :services]).
        where(client_id: batch.map(&:id))
      scope = scope.in_project(@report.project_ids) if @report.project_ids.present? # for consistency with client_scope
      scope.group_by(&:client_id)
    end

    protected def report_client_universe
      HudApr::Fy2020::AprClient
    end

    protected def report_living_situation_universe
      HudApr::Fy2020::AprLivingSituation
    end

    private def a_t
      @a_t ||= report_client_universe.arel_table
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

    private def adults?(enrollments)
      enrollments.any? do |enrollment|
        source_client = enrollment.source_client
        client_start_date = [@report.start_date, enrollment.first_date_in_program].max
        age = source_client.age_on(client_start_date)
        next false if age.blank?

        age >= 18
      end
    end

    private def children?(enrollments)
      enrollments.any? do |enrollment|
        source_client = enrollment.source_client
        client_start_date = [@report.start_date, enrollment.first_date_in_program].max
        age = source_client.age_on(client_start_date)
        next false if age.blank?

        age < 18
      end
    end

    private def unknown_ages?(enrollments)
      enrollments.any? do |enrollment|
        enrollment.source_client.DOB.blank?
      end
    end
  end
end
