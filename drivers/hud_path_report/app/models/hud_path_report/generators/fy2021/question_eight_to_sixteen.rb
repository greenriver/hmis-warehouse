###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2021
  class QuestionEightToSixteen < Base
    include ArelHelper

    QUESTION_NUMBER = 'Q8-Q16'.freeze
    QUESTION_TABLE_NUMBER = 'Q8-Q16'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    TABLE_HEADER = [
      'Persons served during this reporting period:',
      'Count',
    ].freeze

    ROW_LABELS = [
      '8. Number of persons contacted by PATH-funded staff this reporting period',
      '9. Number of new persons contacted this reporting period in a PATH Street Outreach project',
      '10. Number of new persons contacted this reporting period in a PATH Services Only project',
      '11. Total number of new persons contacted this reporting period (#9 + #10 = total new clients contacted)',
      '12a. Instances of contact this reporting period prior to date of enrollment',
      '12b. Total instances of contact during the reporting period',
      '13a. Number of new persons contacted this reporting period who could not be enrolled because of ineligibility for PATH',
      '13b. Number of new persons contacted this reporting period who could not be enrolled because provider was unable to locate the client',
      '14. Number of new persons contacted this reporting period who became enrolled in PATH',
      '15. Number with active, enrolled PATH status at any point during the reporting period',
      '16. Number of active, enrolled PATH clients receiving community mental health services through any funding source at any point during the reporting period',
    ].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])
      table_name = QUESTION_TABLE_NUMBER

      metadata = {
        header_row: TABLE_HEADER,
        row_labels: ROW_LABELS,
        first_column: 'B',
        last_column: 'B',
        first_row: 2,
        last_row: 12,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      [
        [active_clients, all_members],
        [new_and_active_clients, in_street_outreach],
        [new_and_active_clients, in_services_only],
        [new_and_active_clients, all_members],
        nil, # These are contact counts, done below
        nil,
        [new_and_active_clients, a_t[:reason_not_enrolled].eq(1)],
        [new_and_active_clients, a_t[:reason_not_enrolled].eq(3)],
        [new_and_active_clients, a_t[:enrolled_client].eq(true)],
        [active_and_enrolled_clients, all_members],
        [active_and_enrolled_clients, received_service(4)],
      ].each_with_index do |(scope, query), index|
        next if scope.nil?

        answer = @report.answer(question: table_name, cell: 'B' + (index + 2).to_s)
        members = universe.members.where(scope).where(query)
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      # Contacts before date of determination
      answer = @report.answer(question: table_name, cell: 'B6')
      members = universe.members.where(active_and_enrolled_clients).where(a_t[:date_of_determination].gt(any(a_t[:contacts])))
      count = 0
      members.each do |member|
        date_of_determination = member.universe_membership.date_of_determination
        count += member.universe_membership.contacts.select { |contact| contact <= date_of_determination }.count
      end
      answer.add_members(members)
      answer.update(summary: count)

      # Contacts in reporting period
      answer = @report.answer(question: table_name, cell: 'B7')
      members = universe.members.where(active_and_enrolled_clients).where(a_t[:contacts].not_eq([]))
      count = 0
      members.each do |member|
        count += member.universe_membership.contacts.count
      end
      answer.add_members(members)
      answer.update(summary: count)

      @report.complete(QUESTION_NUMBER)
    end
  end
end
