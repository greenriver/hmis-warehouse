module ReportGenerators::CAPER::Fy2017
  # Report Validations Table
  class Q5a < Base

    def run!
      if start_report(Reports::CAPER::Fy2017::Q5a.first)
        @answers = setup_questions
        @support = @answers.deep_dup
        @all_clients = fetch_all_clients
        if @all_clients.any?
          data_methods = %i[
            total_number_served
            number_adults
            number_children
            number_unknown_age
            number_leavers
            number_adult_leavers
            number_adult_and_hoh_leavers
            number_stayers
            number_adult_stayers
            number_veterans
            number_chronically_homeless
            number_you_under_25
            number_parenting_youth_under_25
            number_adult_hoh
            number_children_and_unknown_age_hoh
            hoh_and_adult_stayers_of_365_days_or_more
          ]
          data.methods.each_with_index do |method, i|
            send("add_#{method}")
            if i < data_methods.length - 1
              update_report_progress percent: ( 100 * i.to_f / data_methods.length ).round
            end
          end
        end
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def fetch_all_clients
      columns = columnize(
        client_id:    sh_t, 
        project_id:   sh_t,
        project_name: sh_t,
        FirstName: c_t,
        LastName:  c_t,
      )
      all_client_scope.
        joins( :project, :enrollment ).
        order(date: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.map do |enrollment|
          enrollment[:age] = age_for_report(dob: enrollment[:DOB], enrollment: enrollment)
          enrollment
        end.group_by do |row|
          row[:client_id]
        end
    end

    def typical_client_data(key, sorted)
      @answers[key][:value] = sorted.count
      @support[key][:support] = add_support(
        headers: ['Client ID', 'First Name', 'LastName'],
        data: sorted.map do |_,data|
          datum = data.is_a?(Array) ? data.first : data
          datum.values_at :client_id, :FirstName, :LastName
        end
      )
    end

    def add_total_number_served
      filtered = @all_clients
      sorted = filtered.sort_by(&:first)
      typical_client_data :q5a_b1, sorted
    end

    def add_number_adults
      filtered = @all_clients.select{ |h| adult? h[:age] }
      sorted = filtered.sort_by{ |h| h[:client_id] }
      typical_client_data :q5a_b2, sorted
    end

    def add_number_children
      filtered = @all_clients.select{ |h| child? h[:age] }
      sorted = filtered.sort_by{ |h| h[:client_id] }
      typical_client_data :q5a_b3, sorted
    end

    def add_number_unknown_age
      filtered = @all_clients.reject{ |h| h[:age].present? }
      sorted = filtered.sort_by{ |h| h[:client_id] }
      typical_client_data :q5a_b4, sorted
    end

    def add_number_leavers
      filtered = leavers
      sorted = filtered.sort_by{ |h| h[:client_id] }
      typical_client_data :q5a_b5, sorted
    end

    def add_number_adult_leavers

    end

    def add_number_adult_and_hoh_leavers

    end

    def add_number_stayers

    end

    def add_number_adult_stayers

    end

    def add_number_veterans

    end

    def add_number_chronically_homeless

    end

    def add_number_you_under_25

    end

    def add_number_parenting_youth_under_25

    end

    def add_number_adult_hoh

    end

    def add_number_children_and_unknown_age_hoh

    end

    def add_hoh_and_adult_stayers_of_365_days_or_more

    end

    def setup_questions
      {
        q5a_a1: {
          title:  nil,
          value: 'Total number of persons served',
        },
        q5a_a2: {
          title:  nil,
          value: 'Number of adults (age 18 or over)',
        },
        q5a_a3: {
          title:  nil,
          value: 'Number of children (under age 18)',
        },
        q5a_a4: {
          title:  nil,
          value: 'Number of persons with unknown age',
        },
        q5a_a5: {
          title:  nil,
          value: 'Number of leavers',
        },
        q5a_a6: {
          title:  nil,
          value: 'Number of adult leavers',
        },
        q5a_a7: {
          title:  nil,
          value: 'Number of adult and head of household leavers',
        },
        q5a_a8: {
          title:  nil,
          value: 'Number of stayers',
        },
        q5a_a9: {
          title:  nil,
          value: 'Number of adult stayers',
        },
        q5a_a10: {
          title:  nil,
          value: 'Number of veterans',
        },
        q5a_a11: {
          title:  nil,
          value: 'Number of chronically homeless persons',
        },
        q5a_a12: {
          title:  nil,
          value: 'Number of youth under age 25',
        },
        q5a_a13: {
          title:  nil,
          value: 'Number of parenting youth under age 25 with children',
        },
        q5a_a14: {
          title:  nil,
          value: 'Number of adult heads of household',
        },
        q5a_a15: {
          title:  nil,
          value: 'Number of child and unknown-age heads of household',
        },
        q5a_a16: {
          title:  nil,
          value: 'Heads of households and adult stayers in the project 365 days or more',
        },

        q5a_b1: {
          title:  'Total number of persons served',
          value: 0,
        },
        q5a_b2: {
          title:  'Number of adults (age 18 or over)',
          value: 0,
        },
        q5a_b3: {
          title:  'Number of children (under age 18)',
          value: 0,
        },
        q5a_b4: {
          title:  'Number of persons with unknown age',
          value: 0,
        },
        q5a_b5: {
          title:  'Number of leavers',
          value: 0,
        },
        q5a_b6: {
          title:  'Number of adult leavers',
          value: 0,
        },
        q5a_b7: {
          title:  'Number of adult and head of household leavers',
          value: 0,
        },
        q5a_b8: {
          title:  'Number of stayers',
          value: 0,
        },
        q5a_b9: {
          title:  'Number of adult stayers',
          value: 0,
        },
        q5a_b10: {
          title:  'Number of veterans',
          value: 0,
        },
        q5a_b11: {
          title:  'Number of chronically homeless persons',
          value: 0,
        },
        q5a_b12: {
          title:  'Number of youth under age 25',
          value: 0,
        },
        q5a_b13: {
          title:  'Number of parenting youth under age 25 with children',
          value: 0,
        },
        q5a_b14: {
          title:  'Number of adult heads of household',
          value: 0,
        },
        q5a_b15: {
          title:  'Number of child and unknown-age heads of household',
          value: 0,
        },
        q5a_b16: {
          title:  'Heads of households and adult stayers in the project 365 days or more',
          value: 0,
        },
      }
    end

  end
end