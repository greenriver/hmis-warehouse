###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ReportGenerators::DataQuality::Fy2017
  class Q6 < Base
    def run!
      if start_report(Reports::DataQuality::Fy2017::Q6.first)
        @answers = setup_questions()
        @support = @answers.deep_dup
        @clients_with_issues = Set.new
        @all_clients = fetch_all_clients()
        add_entry_time_answers()

        update_report_progress(percent: 50)
        add_exit_time_answers()

        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def add_entry_time_answers
      buckets = {
        q6_b2: {
          range: -> (num) {num == 0},
          clients: Hash.new,
        },
        q6_b3: {
          range: -> (num) {(1..3).include?(num)},
          clients: Hash.new,
        },
        q6_b4: {
          range: -> (num) {(4..6).include?(num)},
          clients: Hash.new,
        },
        q6_b5: {
          range: -> (num) {(7..10).include?(num)},
          clients: Hash.new,
        },
        q6_b6: {
          range: -> (num) {num > 10},
          clients: Hash.new,
        },
      }

      @all_clients.each do |id, enrollments|
        enrollment = enrollments.last
        date_diff = (enrollment[:first_date_in_program].to_date - enrollment[:entry_created_at].to_date).abs
        buckets.each do |k,bucket|
          if bucket[:range].call(date_diff)
            bucket[:clients][id] = enrollment
            next
          end
        end
      end

      buckets.each do |k,bucket|
        clients = bucket[:clients]
        @answers[k][:value] = clients.size
        @support[k][:support] = add_support(
          headers: ['Client ID', 'Project', 'Entry', 'Exit', 'Created Date', 'Elapsed'],
          data: clients.map do |id, enrollment|
            [
              id,
              enrollment[:project_name],
              enrollment[:first_date_in_program],
              enrollment[:last_date_in_program],
              enrollment[:entry_created_at].to_date,
              (enrollment[:first_date_in_program] - enrollment[:entry_created_at].to_date).abs.to_i
            ]
          end
        )
      end
    end

    def add_exit_time_answers
      buckets = {
        q6_c2: {
          range: -> (num) {num == 0},
          clients: Hash.new,
        },
        q6_c3: {
          range: -> (num) {(1..3).include?(num)},
          clients: Hash.new,
        },
        q6_c4: {
          range: -> (num) {(4..6).include?(num)},
          clients: Hash.new,
        },
        q6_c5: {
          range: -> (num) {(7..10).include?(num)},
          clients: Hash.new,
        },
        q6_c6: {
          range: -> (num) {num > 10},
          clients: Hash.new,
        },
      }

      leavers.keys.each do |id|
        next unless @all_clients[id].present?
        enrollment = @all_clients[id].last
        date_diff = (enrollment[:last_date_in_program].to_date - enrollment[:exit_created_at].to_date).abs
        buckets.each do |k,bucket|
          if bucket[:range].call(date_diff)
            bucket[:clients][id] = enrollment
            next
          end
        end
      end

      buckets.each do |k,bucket|
        clients = bucket[:clients]
        @answers[k][:value] = clients.size
        @support[k][:support] = add_support(
          headers: ['Client ID', 'Project', 'Entry', 'Exit', 'Created Date', 'Elapsed'],
          data: clients.map do |id, enrollment|
            [
              id,
              enrollment[:project_name],
              enrollment[:first_date_in_program],
              enrollment[:last_date_in_program],
              enrollment[:exit_created_at].to_date,
              (enrollment[:last_date_in_program] - enrollment[:exit_created_at].to_date).abs.to_i
            ]
          end
        )
      end
    end

    def fetch_all_clients
      columns = {
        client_id: :client_id,
        first_date_in_program: :first_date_in_program,
        last_date_in_program: :last_date_in_program,
        project_name: :project_name,
        entry_created_at: e_t[:DateCreated].to_sql,
        exit_created_at: ex_t[:DateCreated].to_sql,
      }

      active_client_scope.
        joins(:enrollment).
        includes(enrollment: :exit).
        order(date: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          row[:client_id]
        end
    end

    def setup_questions
      {
        q6_a1: {
          title:  nil,
          value: 'Time for Record Entry',
        },
        q6_b1: {
          title:  nil,
          value: 'Number of Project Entry Records',
        },
        q6_c1: {
          title:  nil,
          value: 'Number of Project Exit Records',
        },
        q6_b2: {
          title:  'Number of Project Entry Records - 0 days',
          value: 0,
        },
        q6_c2: {
          title:  'Number of Project Exit Records - 0 days',
          value: 0,
        },
        q6_b3: {
          title:  'Number of Project Entry Records - 1-3 days',
          value: 0,
        },
        q6_c3: {
          title:  'Number of Project Exit Records - 1-3 days',
          value: 0,
        },
        q6_b4: {
          title:  'Number of Project Entry Records - 4-6 days',
          value: 0,
        },
        q6_c4: {
          title:  'Number of Project Exit Records - 4-6 days',
          value: 0,
        },
        q6_b5: {
          title:  'Number of Project Entry Records - 7-10 days',
          value: 0,
        },
        q6_c5: {
          title:  'Number of Project Exit Records - 7-10 days',
          value: 0,
        },
        q6_b6: {
          title:  'Number of Project Entry Records - 11+ days',
          value: 0,
        },
        q6_c6: {
          title:  'Number of Project Exit Records - 11+ days',
          value: 0,
        },

      }
    end
  end
end