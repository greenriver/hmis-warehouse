module ReportGenerators::CAPER::Fy2017
  # Point-in-Time Count of Households on the Last Wednesday
  class Q8b < Base

    def run!
      raise "this is just stubbed in!" # still need to write code that converts subsets of clients to households as in q8a
      if start_report(Reports::CAPER::Fy2017::Q8b.first)
        @answers = setup_questions
        @support = @answers.deep_dup
        @all_clients = fetch_all_clients
        update_report_progress percent: 50
        if @all_clients.any?
          data_methods = %i[
            xxx
            yyy
            zzz
          ]
          data_methods.each_with_index do |method, i|
            send("add_#{method}")
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

        # intersect the standard scope with the multiple-range scope
        open_between_any(
          [ january, april, july, october ].map{ |d| [ d, d + 1.day ] }
        ).

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

    def clients_for_date(date)
      all_clients.map do |id, enrollments|
        enrollments_for_date = enrollments.select do |enrollment|
          s, e = enrollment.values_at :first_date_in_program, :last_date_in_program
          (s..e).include? date
        end
        [ id, enrollments_for_date ] if enrollments_for_date.any?
      end
    end

    def january
      @january ||= last_wednesday_in :january
    end

    def april
      @april ||= last_wednesday_in :april
    end

    def july
      @july ||= last_wednesday_in :july
    end

    def october
      @october ||= last_wednesday_in :october
    end

    def last_wednesday_in(month, year=Date.today.cwyear)
      month = case month
      when Integer
        month
      when :january
        1
      when :april
        4
      when :july
        7
      when :october
        10
      else
        raise "cannot understand #{month} as a month"
      end
      date = Time.new( year, month, 22 ).to_date # get as close as we can to the end of the month to start with
      delta = ( 10 - date.cwday ) % 7 # shift it to the closest Wednesday after
      date += delta.days
      loop do
        d = date + 7.days
        break if d.mon != date.mon
        date = d
      end
      date
    end

    def setup_questions
      {
        q8b_b1: {
          title:  nil,
          value: 'Total',
        },
        q8b_c1: {
          title:  nil,
          value: 'Without Children',
        },
        q8b_d1: {
          title:  nil,
          value: 'With Children and Adults',
        },
        q8b_e1: {
          title:  nil,
          value: 'With Only Children',
        },
        q8b_f1: {
          title:  nil,
          value: 'Unknown Household Type',
        },

        q8b_a2: {
          title:  nil,
          value: 'January',
        },
        q8b_b2: {
          title: 'Total - January',
          value:  0,
        },
        q8b_c2: {
          title: 'Without Children - January',
          value:  0,
        },
        q8b_d2: {
          title: 'With Children and Adults - January',
          value:  0,
        },
        q8b_e2: {
          title: 'With Only Children - January',
          value:  0,
        },
        q8b_f2: {
          title: 'Unknown Household Type - January',
          value:  0,
        },

        q8b_a3: {
          title:  nil,
          value: 'April',
        },
        q8b_b3: {
          title: 'Total - April',
          value:  0,
        },
        q8b_c3: {
          title: 'Without Children - April',
          value:  0,
        },
        q8b_d3: {
          title: 'With Children and Adults - April',
          value:  0,
        },
        q8b_e3: {
          title: 'With Only Children - April',
          value:  0,
        },
        q8b_f3: {
          title: 'Unknown Household Type - April',
          value:  0,
        },

        q8b_a4: {
          title:  nil,
          value: 'July',
        },
        q8b_b4: {
          title: 'Total - July',
          value:  0,
        },
        q8b_c4: {
          title: 'Without Children - July',
          value:  0,
        },
        q8b_d4: {
          title: 'With Children and Adults - July',
          value:  0,
        },
        q8b_e4: {
          title: 'With Only Children - July',
          value:  0,
        },
        q8b_f4: {
          title: 'Unknown Household Type - July',
          value:  0,
        },

        q8b_a5: {
          title:  nil,
          value: 'October',
        },
        q8b_b5: {
          title: 'Total - October',
          value:  0,
        },
        q8b_c5: {
          title: 'Without Children - October',
          value:  0,
        },
        q8b_d5: {
          title: 'With Children and Adults - October',
          value:  0,
        },
        q8b_e5: {
          title: 'With Only Children - October',
          value:  0,
        },
        q8b_f5: {
          title: 'Unknown Household Type - October',
          value:  0,
        },

      }
    end

  end
end