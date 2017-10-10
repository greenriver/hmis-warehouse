module ReportGenerators::CAPER::Fy2017
  class Q7a < Base
    attr :all_clients, :clients_by_household
    # Number of Persons Served
    # using logic from app/models/report_generators/ahar/fy2017/base.rb
    def run!
      if start_report(Reports::CAPER::Fy2017::Q7a.first)
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
          data_methods = %i[
            adult
            child
            wont_say
            not_collected
            total
          ]
          data_methods.each_with_index do |method, i|
            send("add_#{method}_answers")
            if i < data_methods.length - 1
              update_report_progress percent: 50 + ( 50 * i.to_f / data_methods.length ).round
            end
          end
        end
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def add_adult_answers
      individuals = all_clients.select{ |id,(*,enrollment)| enrollment[:age].to_i >= ADULT }.keys
      @adults = persons_served individuals
      add_answers '2', @adults, [ 'b', 'c', 'd', nil, 'f' ]
    end

    def add_child_answers
      individuals = all_clients.select{ |id,(*,enrollment)| ( a = enrollment[:age] ) && a < ADULT }.keys
      @children = persons_served individuals
      add_answers '3', @children, [ 'b', nil, 'd', 'e', 'f' ]
    end

    def add_wont_say_answers
      individuals = all_clients.select{ |id,(*,enrollment)| doesnt_know_or_refused? enrollment }.keys
      @wont_say = persons_served individuals
      add_answers '4', @wont_say, %w( b c d e f )
    end

    def add_not_collected_answers
      individuals = all_clients.select{ |id,(*,enrollment)| data_not_collected? enrollment }.keys
      @not_collected = persons_served individuals
      add_answers '5', @not_collected, %w( b c d e f )
    end

    def add_total_answers
      bins = {
        total:               [],
        without_children:    [],
        children_and_adults: [],
        only_children:       [],
        unknown:             [],
      }
      [ @adults, @children, @wont_say, @not_collected ].each do |type|
        type.each do |k,v|
          bins[k] += v
        end
      end
      add_answers '6', bins, %w( b c d e f )
    end

    def add_answers row, bins, columns
      bins.keys.zip(columns).each do |type, column|
        next unless column
        ids = bins[type]
        key = "q7a_#{column}#{row}".to_sym
        @answers[key][:value] = ids.size
        @support[key][:support] = add_support(
          headers: ['Client ID', 'Project', 'Age'],
          data: all_clients.slice(*ids).map do |id, (*,enrollment)|
            age = enrollment[:age] || HUD.dob_data_quality(enrollment[:DOBDataQuality])
            [ id, enrollment[:project_name], age ]
          end
        )
      end
    end

    # bin the clients
    def persons_served(client_ids)
      bins = {
        total:               client_ids,
        without_children:    [],
        children_and_adults: [],
        only_children:       [],
        unknown:             [],
      }
      client_ids.each do |id|
        enrollment = all_clients[id].last
        household_id = household_id(enrollment)
        bins[households[household_id]] << id
      end
      bins
    end

    # I'm not certain that all enrollments will have a household id
    # in this case, the individual is treated as the head of their own household
    def household_id(enrollment)
      enrollment[:household_id].presence || enrollment.values_at( :PersonalID, :data_source_id )
    end

    def doesnt_know_or_refused?(enrollment)
      age, quality = enrollment.values_at( :age, :DOBDataQuality )
      age.nil? && [8,9].include?(quality)
    end

    def data_not_collected?(enrollment)
      age, quality = enrollment.values_at( :age, :DOBDataQuality )
      age.nil? && quality == 99
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
    # FIXME when I wrote this I had forgotten about the method I was overwriting
    # perhaps this should use that
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
        q7a_b1: {
          title:  nil,
          value: 'Total',
        },
        q7a_c1: {
          title:  nil,
          value: 'Without Children',
        },
        q7a_d1: {
          title:  nil,
          value: 'With Children and Adults',
        },
        q7a_e1: {
          title:  nil,
          value: 'With Only Children',
        },
        q7a_f1: {
          title:  nil,
          value: 'Unknown Household Type',
        },

        q7a_a2: {
          title:  nil,
          value: 'Adults',
        },
        q7a_b2: {
          title: 'Total - Adults',
          value:  0,
        },
        q7a_c2: {
          title: 'Without Children - Adults',
          value:  0,
        },
        q7a_d2: {
          title: 'With Children and Adults - Adults',
          value:  0,
        },
        q7a_f2: {
          title: 'Unknown Household Type - Adults',
          value:  0,
        },

        q7a_a3: {
          title:  nil,
          value: 'Children',
        },
        q7a_b3: {
          title: 'Total - Children',
          value:  0,
        },
        q7a_d3: {
          title: 'With Children and Adults - Children',
          value:  0,
        },
        q7a_e3: {
          title: 'With Only Children - Children',
          value:  0,
        },
        q7a_f3: {
          title: 'Unknown Household Type - Children',
          value:  0,
        },

        q7a_a4: {
          title:  nil,
          value: 'Client Doesn’t Know/ Client Refused',
        },
        q7a_b4: {
          title: 'Total - Client Doesn’t Know/ Client Refused',
          value:  0,
        },
        q7a_c4: {
          title: 'Without Children - Client Doesn’t Know/ Client Refused',
          value:  0,
        },
        q7a_d4: {
          title: 'With Children and Adults - Client Doesn’t Know/ Client Refused',
          value:  0,
        },
        q7a_e4: {
          title: 'With Only Children - Client Doesn’t Know/ Client Refused',
          value:  0,
        },
        q7a_f4: {
          title: 'Unknown Household Type - Client Doesn’t Know/ Client Refused',
          value:  0,
        },

        q7a_a5: {
          title:  nil,
          value: 'Data Not Collected',
        },
        q7a_b5: {
          title: 'Total - Data Not Collected',
          value:  0,
        },
        q7a_c5: {
          title: 'Without Children - Data Not Collected',
          value:  0,
        },
        q7a_d5: {
          title: 'With Children and Adults - Data Not Collected',
          value:  0,
        },
        q7a_e5: {
          title: 'With Only Children - Data Not Collected',
          value:  0,
        },
        q7a_f5: {
          title: 'Unknown Household Type - Data Not Collected',
          value:  0,
        },

        q7a_a6: {
          title:  nil,
          value: 'Total',
        },
        q7a_b6: {
          title: 'Total - Total',
          value:  0,
        },
        q7a_c6: {
          title: 'Without Children - Total',
          value:  0,
        },
        q7a_d6: {
          title: 'With Children and Adults - Total',
          value:  0,
        },
        q7a_e6: {
          title: 'With Only Children - Total',
          value:  0,
        },
        q7a_f6: {
          title: 'Unknown Household Type - Total',
          value:  0,
        },
      }
    end

  end
end