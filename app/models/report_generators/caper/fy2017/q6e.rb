module ReportGenerators::CAPER::Fy2017
  # Data Quality: Timeliness
  # this is more or less equivalent to the fy2016 data quality question q6
  class Q6e < Base

    def run!
      if start_report(Reports::CAPER::Fy2017::Q6e.first)
        @answers = setup_questions
        @support = @answers.deep_dup
        @all_clients = fetch_all_clients
        update_report_progress percent: 33
        if @all_clients.any?
          data_methods = %i[
            entry_time_answers
            exit_time_answers
          ]
          data_methods.each_with_index do |method, i|
            send("add_#{method}")
            if i < data_methods.length - 1
              update_report_progress percent: 33 + ( 67 * i.to_f / data_methods.length ).round
            end
          end
        end
        finish_report
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def fetch_all_clients
      columns = columnize(
        client_id:             sh_t,  
        first_date_in_program: sh_t,
        last_date_in_program:  sh_t,
        project_name:          sh_t,
        DateCreated: e_t,
      ).merge({
        exit_created_at: x_t[:DateCreated].as('exit_created_at').to_sql
      })
      
      all_client_scope.
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

    def add_entry_time_answers
      buckets = {
        q6e_b2: 0..0,
        q6e_b3: 1..3,
        q6e_b4: 4..6,
        q6e_b5: 7..10,
        q6e_b6: 11..Float::INFINITY
      }.map do |key, range|
        [ key, { range: range, clients: {} } ]
      end.to_h

      @all_clients.each do |id, (*,enrollment)|
        f, c = enrollment.values_at( :first_date_in_program, :DateCreated ).map(&:to_date)
        date_diff = ( f - c ).abs
        enrollment[:elapsed] = date_diff
        buckets.each do |k,bucket|
          if bucket[:range].include? date_diff
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
              enrollment[:DateCreated].to_date,
              enrollment[:elapsed].to_i
            ]
          end
        )
      end
    end

    def add_exit_time_answers
      buckets = {
        q6e_c2: 0..0,
        q6e_c3: 1..3,
        q6e_c4: 4..6,
        q6e_c5: 7..10,
        q6e_c6: 11..Float::INFINITY
      }.map do |key, range|
        [ key, { range: range, clients: {} } ]
      end.to_h

      leavers.keys.each do |id|
        enrollment = @all_clients[id].last
        l, x = enrollment.values_at( :last_date_in_program, :exit_created_at ).map{ |d| d.try :to_date }
        date_diff = ( l - ( x || Date.today ) ).abs
        enrollment[:elapsed] = date_diff
        buckets.each do |k,bucket|
          if bucket[:range].include? date_diff
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
              enrollment[:exit_created_at]&.to_date,
              enrollment[:elapsed].to_i
            ]
          end
        )
      end
    end

    def setup_questions
      {
        q6e_a1: {
          title:  nil,
          value: 'Time for Record Entry',
        },
        q6e_b1: {
          title:  nil,
          value: 'Number of Project Start Records',
        },
        q6e_c1: {
          title:  nil,
          value: 'Number of Project Exit Records',
        },
        q6e_b2: {
          title:  'Number of Project Start Records - 0 days',
          value: 0,
        },
        q6e_c2: {
          title:  'Number of Project Exit Records - 0 days',
          value: 0,
        },
        q6e_b3: {
          title:  'Number of Project Start Records - 1-3 days',
          value: 0,
        },
        q6e_c3: {
          title:  'Number of Project Exit Records - 1-3 days',
          value: 0,
        },
        q6e_b4: {
          title:  'Number of Project Start Records - 4-6 days',
          value: 0,
        },
        q6e_c4: {
          title:  'Number of Project Exit Records - 4-6 days',
          value: 0,
        },
        q6e_b5: {
          title:  'Number of Project Start Records - 7-10 days',
          value: 0,
        },
        q6e_c5: {
          title:  'Number of Project Exit Records - 7-10 days',
          value: 0,
        },
        q6e_b6: {
          title:  'Number of Project Start Records - 11+ days',
          value: 0,
        },
        q6e_c6: {
          title:  'Number of Project Exit Records - 11+ days',
          value: 0,
        },
      }
    end

  end
end