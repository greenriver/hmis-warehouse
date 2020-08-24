###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionSix < HudReports::QuestionBase
    include ArelHelper

    QUESTION_NUMBER = 'Q6'
    QUESTION_TABLE_NUMBERS = ('Q6a'..'Q6f').to_a

    def run!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q6a_data_quality

      # Q6b
      metadata = {
        header_row: ['Data Element', 'Error Count', '% of Error Rate'],
        row_labels: [ 'Veteran Status (3.07)', 'Project Start Date (3.10)', 'Relationship to Head of Household (3.15)',
          'Client Location (3.16)', 'Disabling Condition (3.08)'],
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: 'Q6b').update(metadata: metadata)

      # Q6c
      metadata = {
        header_row: ['Data Element', 'Error Count', '% of Error Rate'],
        row_labels: [ 'Destination (3.12)', 'Income and Sources (4.02) at Start',
          'Income and Sources (4.02) at Annual Assessment', 'Income and Sources (4.02) at Exit'],
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 5,
      }
      @report.answer(question: 'Q6c').update(metadata: metadata)

      # Q6d
      metadata = {
        header_row: ['Entering into project type', 'Count of total records', 'Missing time in institution (3.917.2)',
          'Missing time in housing (3.917.2)', 'Approximate Date started (3.917.3) DK/R/missing',
          'Number of times (3.917.4) DK/R/missing', 'Number of months (3.917.5) DK/R/missing',
          '% of records unable to calculate'],
        row_labels: [ 'ES, SH, Street Outreach', 'TH', 'PH (all)', 'Total'],
        first_column: 'B',
        last_column: 'H',
        first_row: 2,
        last_row: 5,
      }
      @report.answer(question: 'Q6d').update(metadata: metadata)

      # Q6e
      metadata = {
        header_row: ['Time for Record Entry', 'Number of Project Start Records', 'Number of Project Exit Records'],
        row_labels: [ '0 days', '1-3 days', '4-6 days', '7-10 days', '11+ days'],
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: 'Q6e').update(metadata: metadata)

      # Q6f
      metadata = {
        header_row: ['Data Element', '# of Records', '# of Inactive Records', ' # % of Inactive Records'],
        row_labels: [ 'Contact (Adults and Heads of Household in Street Outreach or ES – NBN)',
          'Bed Night (All clients in ES – NBN)'],
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 3,
      }
      @report.answer(question: 'Q6f').update(metadata: metadata)

      @report.complete(QUESTION_NUMBER)
    end

    private def a_t
      @a_t ||= report_client_universe.arel_table
    end

    private def q6a_data_quality
      table_name = 'Q6a'
      metadata = {
        header_row: ['Data Element', 'Client Doesn’t Know/Refused', 'Information Missing',
          'Data Issues', 'Total', '% of Error Rate'],
        row_labels: ['Name (3.01)', 'Social Security Number (3.02)', 'Date of Birth (3.03)', 'Race (3.04)',
          'Ethnicity (3.05)', 'Gender (3.06)', 'Overall Score'],
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 8,
      }

      @report.answer(question: table_name).update(metadata: metadata)

      clients = name_quality(table_name: table_name)
      clients = clients.or(ssn_quality(table_name: table_name))
      clients = clients.or(dob_quality(table_name: table_name))
      clients = clients.or(race_quality(table_name: table_name))
      clients = clients.or(simple_quality(table_name: table_name, row: 6, attr: :ethnicity))
      clients = clients.or(simple_quality(table_name: table_name, row: 7, attr: :gender))

      count = clients.distinct.count
      @report.answer(question: table_name, cell: 'E8').update(summary: count)
      @report.answer(question: table_name, cell: 'F8').update(summary: format('%1.4f', count / universe.members.count.to_f ))
    end

    private def name_quality(table_name:)
      # Name DK/R
      answer = @report.answer(question: table_name, cell: 'B2')
      dkr_members = universe.members.where(a_t[:name_quality].in([8, 9]))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # Name missing
      answer = @report.answer(question: table_name, cell: 'C2')
      m_members = universe.members.where(
        a_t[:first_name].eq(nil).
          or(a_t[:last_name].eq(nil)),
      )
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # Name quality
      answer = @report.answer(question: table_name, cell: 'D2')
      q_members = universe.members.where(a_t[:name_quality].eq(2))
      answer.add_members(q_members)
      answer.update(summary: q_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E2')
      total_members = dkr_members.or(m_members.or(q_members))
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F2')
      answer.update(summary: format('%1.4f', total_members.count / universe.members.count.to_f ))

      total_members
    end

    private def ssn_quality(table_name:)
      # SSN DK/R
      answer = @report.answer(question: table_name, cell: 'B3')
      dkr_members = universe.members.where(a_t[:ssn_quality].in([8, 9]))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # SSN missing
      answer = @report.answer(question: table_name, cell: 'C3')
      m_members = universe.members.where(a_t[:ssn].eq(nil))
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # SSN quality
      answer = @report.answer(question: table_name, cell: 'D3')
      q_member_ids = []
      universe.members.find_each do |u_member|
        member = u_member.universe_membership
        q_member_ids << u_member.id if member.ssn_quality == 2 || !HUD.valid_social?(member.ssn)
      end
      q_members = universe.members.where(id: q_member_ids)
      answer.add_members(q_members)
      answer.update(summary: q_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E3')
      total_members = dkr_members.or(m_members.or(q_members))
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F3')
      answer.update(summary: format('%1.4f', total_members.count / universe.members.count.to_f ))

      total_members
    end

    private def dob_quality(table_name:)
      # DOB DK/R
      answer = @report.answer(question: table_name, cell: 'B4')
      dkr_members = universe.members.where(a_t[:dob_quality].in([8, 9]))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # DOB missing
      answer = @report.answer(question: table_name, cell: 'C4')
      m_members = universe.members.where(a_t[:dob].eq(nil))
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # DOB quality
      answer = @report.answer(question: table_name, cell: 'D4')
      q_member_ids = []
      universe.members.find_each do |u_member|
        member = u_member.universe_membership
        q_member_ids << u_member.id if member.dob_quality == 2 || !valid_dob?(member)
      end
      q_members = universe.members.where(id: q_member_ids)
      answer.add_members(q_members)
      answer.update(summary: q_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E4')
      total_members = dkr_members.or(m_members.or(q_members))
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F4')
      answer.update(summary: format('%1.4f', total_members.count / universe.members.count.to_f ))

      total_members
    end

    private def valid_dob?(member)
      return true if member.dob.blank? # Was counted in missing

      return false if member.dob < '1915-01-01'.to_date
      return false if member.dob > member.enrollment_created
      return false if member.head_of_household && member.dob > member.first_date_in_program

      true
    end

    private def race_quality(table_name:)
      # Race DK/R / compute missing
      answer = @report.answer(question: table_name, cell: 'B5')
      dkr_member_ids = []
      m_member_ids = []
      universe.members.find_each do |u_member|
        member = u_member.universe_membership
        dkr_member_ids << u_member.id if member.race.any?(8) || member.race.any?(9)
        m_member_ids << u_member.id if member.race.all?(nil)
      end
      dkr_members = universe.members.where(id: dkr_member_ids)
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # Race missing
      answer = @report.answer(question: table_name, cell: 'C5')
      m_members = universe.members.where(id: m_member_ids)
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E5')
      total_members = dkr_members.or(m_members)
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F5')
      answer.update(summary: format('%1.4f', total_members.count / universe.members.count.to_f ))

      total_members
    end

    private def simple_quality(table_name:, row:, attr:)
      row_label = row.to_s
      # DK/R
      answer = @report.answer(question: table_name, cell: 'B' + row_label)
      dkr_members = universe.members.where(a_t[attr].in([8, 9]))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # Missing
      answer = @report.answer(question: table_name, cell: 'C' + row_label)
      m_members = universe.members.where(a_t[attr].eq(nil))
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E' + row_label)
      total_members = dkr_members.or(m_members)
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F' + row_label)
      answer.update(summary: format('%1.4f', total_members.count / universe.members.count.to_f ))

      total_members
    end

    private def universe
      @universe ||= begin
        universe_cell = @report.universe(QUESTION_NUMBER)

        @generator.client_scope.find_in_batches do |batch|
          pending_associations = {}
          clients_with_enrollments = clients_with_enrollments(batch)

          batch.each do |client|
            last_service_history_enrollment = clients_with_enrollments[client.id].last
            source_client = last_service_history_enrollment.source_client
            client_start_date = [@report.start_date, last_service_history_enrollment.first_date_in_program].max
            pending_associations[client] = report_client_universe.new(
              first_name: source_client.FirstName,
              last_name: source_client.LastName,
              name_quality: source_client.NameDataQuality,
              ssn: source_client.SSN,
              ssn_quality: source_client.SSNDataQuality,
              dob: source_client.DOB,
              dob_quality: source_client.DOBDataQuality,
              age: source_client.age_on(client_start_date),
              head_of_household: last_service_history_enrollment.head_of_household,
              first_date_in_program: last_service_history_enrollment.first_date_in_program,
              enrollment_created: last_service_history_enrollment.enrollment.DateCreated,
              race: HUD.races.keys.map { |key| source_client.public_send(key) },
              ethnicity: source_client.Ethnicity,
              gender: source_client.Gender,
            )
          end
          report_client_universe.import(pending_associations.values)
          universe_cell.add_universe_members(pending_associations)
        end

        universe_cell
      end
    end

    private def clients_with_enrollments(batch)
      GrdaWarehouse::ServiceHistoryEnrollment.
        in_project(@report.project_ids).
        joins(:enrollment).
        preload(enrollment: [:client, :disabilities, :current_living_situations]).
        where(client_id: batch.map(&:id)).
        order(first_date_in_program: :asc).
        group_by(&:client_id)
    end

    private def report_client_universe
      HudApr::Fy2020::AprClient
    end
  end
end