###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024::Dq::QuestionTwo
  extend ActiveSupport::Concern

  included do
    private def generate_q2(table_name)
      metadata = {
        header_row: [
          'Data Element',
          label_for(:dkptr),
          'Information Missing',
          'Data Issues',
          'Total',
          '% of Error Rate',
        ],
        row_labels: [
          'Name (3.01)',
          'Social Security Number (3.02)',
          'Date of Birth (3.03)',
          'Race/Ethnicity (3.04)',
          'Gender (3.06)',
          'Overall Score',
        ],
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)
      universe_members = universe.members.where(engaged_clause)

      clients = name_quality(table_name: table_name, universe_members: universe_members)
      # NOTE: These "x_quality" methods are writing report data
      clients = clients.or(ssn_quality(table_name: table_name, universe_members: universe_members))
      clients = clients.or(dob_quality(table_name: table_name, universe_members: universe_members))
      clients = clients.or(race_and_ethnicity_quality(table_name: table_name, universe_members: universe_members))
      # clients = clients.or(simple_quality(table_name: table_name, row: 6, attr: :ethnicity))
      clients = clients.or(simple_quality(table_name: table_name, row: 6, attr: :gender_multi, universe_members: universe_members))

      count = clients.distinct.count
      @report.answer(question: table_name, cell: 'E7').update(summary: count)
      @report.answer(question: table_name, cell: 'F7').update(summary: percentage(count / universe_members.count.to_f))
    end

    private def name_quality(table_name:, universe_members:)
      # Name DK/R
      answer = @report.answer(question: table_name, cell: 'B2')
      dkr_members = universe_members.where(a_t[:name_quality].in([8, 9]))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # Name missing
      # Name DQ 99 or name missing and we didn't already count it for DK/R
      answer = @report.answer(question: table_name, cell: 'C2')
      m_members = universe_members.where(
        a_t[:name_quality].eq(99).or(
          a_t[:name_quality].not_in([8, 9]).
            and(
              a_t[:first_name].eq(nil).
                or(a_t[:last_name].eq(nil)),
            ),
        ),
      )
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # Name quality
      answer = @report.answer(question: table_name, cell: 'D2')
      q_members = universe_members.where(a_t[:name_quality].eq(2))
      answer.add_members(q_members)
      answer.update(summary: q_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E2')
      total_members = dkr_members.or(m_members.or(q_members))
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F2')
      answer.update(summary: percentage(total_members.count / universe_members.count.to_f))

      total_members
    end

    private def ssn_quality(table_name:, universe_members:)
      # SSN DK/R
      answer = @report.answer(question: table_name, cell: 'B3')
      dkr_members = universe_members.where(a_t[:ssn_quality].in([8, 9]))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # SSN missing
      answer = @report.answer(question: table_name, cell: 'C3')
      m_members = universe_members.where(
        a_t[:ssn].eq(nil).and(a_t[:ssn_quality].not_in([8, 9])).
          or(a_t[:ssn_quality].eq(99)),
      )
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # SSN quality
      answer = @report.answer(question: table_name, cell: 'D3')
      q_member_ids = []
      universe_members.preload(:universe_membership).find_each do |u_member|
        member = u_member.universe_membership
        q_member_ids << u_member.id if member.ssn_quality == 2 ||
          (member.ssn_quality == 1 && member.ssn.present? && !HudUtility2024.valid_social?(member.ssn))
      end
      q_members = universe_members.where(id: q_member_ids)
      answer.add_members(q_members)
      answer.update(summary: q_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E3')
      total_members = dkr_members.or(m_members.or(q_members))
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F3')
      answer.update(summary: percentage(total_members.count / universe_members.count.to_f))

      total_members
    end

    private def dob_quality(table_name:, universe_members:)
      # DOB DK/R
      answer = @report.answer(question: table_name, cell: 'B4')
      dkr_members = universe_members.where(
        a_t[:dob].eq(nil).and(a_t[:dob_quality].in([8, 9])),
      )
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # DOB missing
      answer = @report.answer(question: table_name, cell: 'C4')
      m_members = universe_members.where(
        a_t[:dob].eq(nil).and(a_t[:dob_quality].not_in([8, 9])),
      )
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # DOB quality
      answer = @report.answer(question: table_name, cell: 'D4')
      q_member_ids = []
      universe_members.find_each do |u_member|
        member = u_member.universe_membership
        q_member_ids << u_member.id if member.dob_quality == 2 ||
          (member.dob_quality == 1 && !valid_dob?(member)) ||
          (member.dob_quality.in?([8, 9, 99]) && member.dob.present?) ||
          (member.dob.present? && member.dob > member.client_created_at)
      end
      q_members = universe_members.where(id: q_member_ids)
      answer.add_members(q_members)
      answer.update(summary: q_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E4')
      total_members = dkr_members.or(m_members.or(q_members))
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F4')
      answer.update(summary: percentage(total_members.count / universe_members.count.to_f))

      total_members
    end

    private def valid_dob?(member)
      return true if member.dob.blank? # Was counted in missing

      return false if member.dob < '1915-01-01'.to_date
      return false if member.dob > member.enrollment_created
      return false if member.head_of_household && member.dob > member.first_date_in_program

      true
    end

    private def race_and_ethnicity_quality(table_name:, universe_members:)
      # in 2024, race and ethnicity are the same column
      race_col = a_t[:race_multi]

      # Race DK/R / compute missing
      answer = @report.answer(question: table_name, cell: 'B5')

      dkr_members = universe_members.where(race_col.in(['8', '9']))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # Race missing
      answer = @report.answer(question: table_name, cell: 'C5')
      m_members = universe_members.where(race_col.eq('99'))
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E5')
      total_members = dkr_members.or(m_members)
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F5')
      answer.update(summary: percentage(total_members.count / universe_members.count.to_f))

      total_members
    end

    private def simple_quality(table_name:, row:, attr:, universe_members:)
      row_label = row.to_s
      # DK/R
      answer = @report.answer(question: table_name, cell: 'B' + row_label)
      dkr_members = universe_members.where(a_t[attr].in([8, 9]))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # Missing
      answer = @report.answer(question: table_name, cell: 'C' + row_label)
      m_members = universe_members.where(
        a_t[attr].eq(nil).
          or(a_t[attr].eq(99)),
      )
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E' + row_label)
      total_members = dkr_members.or(m_members)
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F' + row_label)
      answer.update(summary: percentage(total_members.count / universe_members.count.to_f))

      total_members
    end
  end
end
