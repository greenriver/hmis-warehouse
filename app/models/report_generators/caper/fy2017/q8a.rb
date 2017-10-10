module ReportGenerators::CAPER::Fy2017
  # Number of Households Served
  class Q8a < Base
    attr :all_clients, :clients_by_household
    def run!
      if start_report(Reports::CAPER::Fy2017::Q8a.first)
        @answers = setup_questions
        @support = @answers.deep_dup
        fetch_all_clients
        update_report_progress percent: 50
        @clients_by_household = {}.tap do |bhid|
          all_clients.each do |id, (*,enrollment)|
            household = ( bhid[household_id(enrollment)] ||= [] )
            household << id
          end
        end
        if @all_clients.any?
          add_answers
        end
        finish_report
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def add_answers
      bins = households_served
      bins.keys.zip(%w( b c d e f )).each do |type, column|
        next unless column
        ids = bins[type]
        key = "q8a_#{column}2".to_sym
        @answers[key][:value] = ids.size
        @support[key][:support] = add_support(
          headers: ['Client ID', 'Project', 'Household ID', 'Age'],
          data: all_clients.slice(*ids.flatten).map do |id, (*,enrollment)|
            age = enrollment[:age] || HUD.dob_data_quality(enrollment[:DOBDataQuality])
            [ id, enrollment[:project_name], enrollment[:household_id], age ]
          end
        )
      end
    end

    # bin the households
    def households_served
      bins = {
        total:               all_clients.keys,
        without_children:    [],
        children_and_adults: [],
        only_children:       [],
        unknown:             [],
      }
      households.each do |id, type|
        bins[type] << clients_by_household[id]
      end
      bins
    end

    # I'm not certain that all enrollments will have a household id
    # in this case, the individual is treated as the head of their own household
    def household_id(enrollment)
      enrollment[:household_id].presence || enrollment.values_at( :PersonalID, :data_source_id )
    end

    def fetch_all_clients
      columns = columnize(
        age:                   sh_t,
        client_id:             sh_t,
        first_date_in_program: sh_t,
        data_source_id:        sh_t,
        household_id:          sh_t,
        project_name:          sh_t,
        DOB:            c_t,
        DOBDataQuality: c_t,
        PersonalID:     c_t,
      )

      @all_clients = all_client_scope.
        joins(:project).
        order(date: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.each do |enrollment|
          # see HUD.dob_data_quality
          enrollment[:age] = if [8,9,99].include? enrollment[:DOBDataQuality]
            nil
          else
            age_for_report(dob: enrollment[:DOB], enrollment: enrollment)
          end
        end.group_by do |row|
          row[:client_id]
        end
    end

    # copied with considerable modification from ahar
    def households
      @households ||= clients_by_household.map do |household_id, client_ids|
        child = adult = unknown = 0
        client_ids.each do |id|
          enrollment = all_clients[id].last
          case enrollment[:age]
          when nil
            unknown += 1
          when 0...ADULT
            child += 1
          else
            adult += 1
          end
        end
        household_type = if adult > 0 && child > 0
          :children_and_adults
        elsif adult > 0 && child == 0 && unknown == 0
          :without_children
        elsif adult == 0 && child > 0 && unknown == 0
          :only_children
        else
          :unknown
        end
          
        [ household_id, household_type ]
      end.to_h
    end

    def setup_questions
      {
        q8a_b1: {
          title:  nil,
          value: 'Total',
        },
        q8a_c1: {
          title:  nil,
          value: 'Without Children',
        },
        q8a_d1: {
          title:  nil,
          value: 'With Children and Adults',
        },
        q8a_e1: {
          title:  nil,
          value: 'With Only Children',
        },
        q8a_f1: {
          title:  nil,
          value: 'Unknown Household Type',
        },

        q8a_a2: {
          title:  nil,
          value: 'Total Households',
        },
        q8a_b2: {
          title: 'Total',
          value:  0,
        },
        q8a_c2: {
          title: 'Without Children',
          value:  0,
        },
        q8a_d2: {
          title: 'With Children and Adults',
          value:  0,
        },
        q8a_e2: {
          title: 'With Only Children',
          value:  0,
        },
        q8a_f2: {
          title: 'Unknown Household Type',
          value:  0,
        },

      }
    end

  end
end