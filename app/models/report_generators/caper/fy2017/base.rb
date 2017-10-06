=begin

This is a copy-paste variant of the AHAR report generator base.

See https://www.hudexchange.info/resources/documents/HMIS-Programming-Specifications.pdf
for the spec.

See app/models/report_generators/ahar/fy2017/base.rb for further notes.

=end

module ReportGenerators::CAPER::Fy2017
  class Base
    include ArelHelper
    include ApplicationHelper
    attr_reader :all_clients

    ADULT=18

    def add_filters scope:
      if @report.options['project_id'].delete_if(&:blank?).any?
        project_ids = @report.options['project_id'].delete_if(&:blank?).map(&:to_i)
        scope = scope.joins(:project).where(Project: { id: project_ids})
      end
      if @report.options['data_source_id'].present?
        scope = scope.where(data_source_id: @report.options['data_source_id'].to_i)
      end
      if @report.options['coc_code'].present?
        scope = scope.coc_funded_in(coc_code: @report.options['coc_code'])
      end
      if @report.options['project_type'].delete_if(&:blank?).any?
        project_types = @report.options['project_type'].delete_if(&:blank?).map(&:to_i)
        scope = scope.hud_project_type(project_types)
      end

      return scope
    end

    def coc_t
      GrdaWarehouse::Hud::ProjectCoC.arel_table
    end

    def p_t
      GrdaWarehouse::Hud::Project.arel_table
    end

    def sh_t
      GrdaWarehouse::ServiceHistory.arel_table
    end

    def e_t
      GrdaWarehouse::Hud::Enrollment.arel_table
    end

    def c_t
      GrdaWarehouse::Hud::Client.arel_table
    end

    def d_t
      GrdaWarehouse::Hud::Disability.arel_table
    end

    def o_t
      GrdaWarehouse::Hud::Organization.arel_table
    end

    def act_as_coc_overlay
      nf( 'COALESCE', [ coc_t[:hud_coc_code], coc_t[:CoCCode] ] ).as('CoCCode').to_sql
    end

    def act_as_project_overlay
      nf( 'COALESCE', [ p_t[:act_as_project_type], sh_t[:project_type] ] ).as('project_type').to_sql
    end

    # all the clients which open enrollments that overlap the period in question
    def all_client_scope
      @report_start ||= @report.options['report_start'].to_date
      @report_end ||= @report.options['report_end'].to_date
      client_scope = GrdaWarehouse::ServiceHistory.entry.
        open_between(start_date: @report_start,
          end_date: @report_end).
        joins(:client)

      add_filters(scope: client_scope)
    end

    # likely to be overridden
    def fetch_all_clients
      columns = columnize(
        client_id:             sh_t,
        enrollment_group_id:   sh_t,
        project_id:            sh_t,
        data_source_id:        sh_t,
        first_date_in_program: sh_t,
        last_date_in_program:  sh_t,
        VeteranStatus:   c_t,
        NameDataQuality: c_t,
        FirstName:       c_t,
        LastName:        c_t,
        SSN:             c_t,
        SSNDataQuality:  c_t,
        DOB:             c_t,
        DOBDataQuality:  c_t,
        Ethnicity:       c_t,
        Gender:          c_t,
        RaceNone:        c_t,
        DateCreated: e_t,
      ).merge({
        project_type: act_as_project_overlay,
      })
      all_client_scope.
        joins( :project, :enrollment ).
        order(date: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.each do |enrollment|
          enrollment[:age] = age_for_report(dob: enrollment[:DOB], enrollment: enrollment)
        end.group_by do |row|
          row[:client_id]
        end
    end

    # maybe should be moved to subclasses that actually need it
    def leavers
      @report_start ||= @report.options['report_start'].to_date
      @report_end ||= @report.options['report_end'].to_date
      @leavers ||= begin
        # 1. A "system leaver" is any client who has exited from one or more of the relevant projects between [report start date] and [report end date] and who
        # is not active in any of the relevant projects as of the [report end date].
        # 2. The client must be an adult to be included.
        columns = columnize(
          client_id:               sh_t,
          first_date_in_program:   sh_t,
          last_date_in_program:    sh_t,
          project_id:              sh_t,
          age:                     sh_t,
          enrollment_group_id:     sh_t,
          data_source_id:          sh_t,
          project_tracking_method: sh_t,
          project_name:            sh_t,
          household_id:            sh_t,
          destination:             sh_t,
          RelationshipToHoH: e_t,
          DOB:       c_t,
          FirstName: c_t,
          LastName:  c_t,
        )
        
        client_id_scope = GrdaWarehouse::ServiceHistory.entry.
          ongoing(on_date: @report_end)

        client_id_scope = add_filters(scope: client_id_scope)

        leavers_scope = GrdaWarehouse::ServiceHistory.entry.
          ended_between(start_date: @report_start + 1.days, 
            end_date: @report_end + 1.days).
          where.not(
            client_id: client_id_scope.
              select(:client_id).
              distinct
          ).
          joins(:client, :enrollment)
          
        leavers_scope = add_filters(scope: leavers_scope)

        leavers_scope.
          order(client_id: :asc, first_date_in_program: :asc).
          pluck(*columns.values).map do |row|
            Hash[columns.keys.zip(row)]
          end.group_by do |row|
            row[:client_id]
          end.map do |id,enrollments| 
            # We only care about the last enrollment
            enrollment = enrollments.last
            enrollment[:age] = age_for_report(dob: enrollment[:DOB], enrollment: enrollment)
            [id, enrollment]
          end.to_h
      end
    end

    # maybe should be moved to subclasses that actually need it
    def stayers
      @report_end ||= @report.options['report_end'].to_date
      stayers ||= begin
        # 1. A "system stayer" is a client active in any one or more of the relevant projects as of the [report end date]. CoC Performance Measures Programming Specifications
        # 2. The client must have at least 365 days in latest stay to be included in this measure, using either bed-night or entry exit (you have to count the days) 
        # 3. The client must be an adult to be included in this measure.
        columns = columnize(
          client_id:               sh_t,
          first_date_in_program:   sh_t,
          last_date_in_program:    sh_t,
          project_id:              sh_t,
          age:                     sh_t,
          enrollment_group_id:     sh_t,
          data_source_id:          sh_t,
          project_tracking_method: sh_t,
          project_name:            sh_t,
          household_id:            sh_t,
          RelationshipToHoH: e_t,
          DOB:       c_t,
          FirstName: c_t,
          LastName:  c_t,
        )

        stayers_scope = GrdaWarehouse::ServiceHistory.entry.
          ongoing(on_date: @report_end).
          joins(:client, :enrollment)

        stayers_scope = add_filters(scope: stayers_scope)

        stayers_scope.
          order(client_id: :asc, first_date_in_program: :asc).
          pluck(*columns.values).map do |row|
            Hash[columns.keys.zip(row)]
          end.group_by do |row|
            row[:client_id]
          end.map do |id,enrollments| 
            # We only care about the last enrollment
            enrollment = enrollments.last
            enrollment[:age] = age_for_report(dob: enrollment[:DOB], enrollment: enrollment)
            [id, enrollment]
          end.to_h
      end
    end

    # Age should be calculated at report start or enrollment start, whichever is greater
    def age_for_report(dob:, enrollment:)
      @report_start ||= @report.options['report_start'].to_date
      entry_date = enrollment[:first_date_in_program]
      return enrollment[:age] if dob.blank? || entry_date > @report_start
      GrdaWarehouse::Hud::Client.age(dob: dob, date: @report_start)
    end

    def adult?(age)
      age = age[:age] if age.is_a? Hash
      age >= ADULT if age.present?
    end

    def child?(age)
      age = age[:age] if age.is_a? Hash
      age < ADULT if age.present?
    end

    def unknown_age?(age)
      age = age[:age] if age.is_a? Hash
      !age.present?
    end

    def veteran?(status)
      status = status[:VeteranStatus] if status.is_a? Hash
      status == 1
    end

    def head_of_household?(relationship)
      relationship = relationship[:RelationshipToHoH] if relationship.is_a? Hash
      relationship.to_i == 1
    end

    def child_in_household?(relationship)
      relationship = relationship[:RelationshipToHoH] if relationship.is_a? Hash
      relationship.to_i == 2
    end

    def valid_household_relationship?(relationship)
      relationship = relationship[:RelationshipToHoH] if relationship.is_a? Hash
      (1..5).include?(relationship.to_i)
    end

    def homeless_for_one_year? enrollment
      enrollment[:DateToStreetESSH].present? && 
      enrollment[:DateToStreetESSH].to_date <= (enrollment[:first_date_in_program] - 365.days)
    end

    def valid_coc_code?(code)
      /^[a-zA-Z]{2}-[0-9]{3}$/.match(code).present?
    end

    def start_report(report)
      # Find the first queued report
      @report = ReportResult.where(
        report: report,
        percent_complete: 0
      ).first
      return unless @report.present? 
      Rails.logger.info "Starting report #{@report.report.name}"
      @report.update(percent_complete: 0.01)
    end

    def finish_report
      @report.update(
        percent_complete: 100, 
        results: @answers,
        support: @support,
        completed_at: Time.now
      )
    end

    def add_support headers:, data:
      {
        headers: headers,
        counts: data,
      }
    end

    def update_report_progress percent:
      @report.update(
        percent_complete: percent,
        results: @answers,
        support: @support,
      )
    end

    # maybe should be moved to subclasses that actually need it
    def setup_age_categories
      clients_with_ages = @all_clients.map do |id, enrollments|
        enrollment = enrollments.last
        [id, enrollment[:age]]
      end.to_h
      @adults = clients_with_ages.select do |_, age|
        adult?(age)
      end
      @children = clients_with_ages.select do |_, age|
        child?(age)
      end
      @unknown = clients_with_ages.select do |_, age|
        age.blank?
      end
    end

    # maybe should be moved to subclasses that actually need it
    def anniversary_date(date)
      @report_end ||= @report.options['report_end'].to_date
      date = date.to_date
      # careful of leap years
      if date.month == 2 && date.day == 29
        date += 1.day
      end

      anniversary_date = Date.new(@report_end.year, date.month, date.day)
      anniversary_date = if anniversary_date > @report_end then anniversary_date - 1.year else anniversary_date end
    end

    # maybe should be moved to subclasses that actually need it
    def households
      @households ||= begin
        counter = 0
        hh = {}
        flat_clients = @all_clients.values.flatten(1).group_by do |enrollment|
          [
            enrollment[:data_source_id],
            enrollment[:project_id],
            enrollment[:household_id],
            enrollment[:first_date_in_program],
          ]
        end
        @all_clients.each do |id, enrollments|
          enrollment = enrollments.last
          key = [
            enrollment[:data_source_id],
            enrollment[:project_id],
            enrollment[:household_id],
            enrollment[:first_date_in_program],
          ]
          household = flat_clients[key]

          counter += 1
          if counter % 500 == 0
            GC.start
            # log_with_memory("Building households #{counter} of #{@all_clients.size}")
          end
          hh[id] = {
            key: key,
            household: household,
          }
        end
        hh
      end
      @households
    end

    # maybe should be moved to subclasses that actually need it
    def adult_heads
      households.select do |id, household|
        household[:household].select do |member|
          adult?(member[:age]) && head_of_household?(member)
        end.any?
      end
    end

    # maybe should be moved to subclasses that actually need it
    def other_heads
      households.select do |id, household|
        household[:household].select do |member|
          ! adult?(member[:age]) && head_of_household?(member)
        end.any?
      end
    end

    # maybe should be moved to subclasses that actually need it
    def stay_length(client_id:, entry_date:, enrollment_group_id:)
      GrdaWarehouse::ServiceHistory.service.
        where(
          client_id: client_id, 
          first_date_in_program: entry_date,
          enrollment_group_id: enrollment_group_id
        ).
        select(:date).
        distinct.
        count
    end

    # maybe should be moved to subclasses that actually need it
    def adult_stayers_and_heads_of_household_stayers
      @adult_stayers_and_heads_of_household_stayers ||= stayers.select do |_, enrollment|
        adult?(enrollment) || head_of_household?(enrollment)
      end
    end

    # maybe should be moved to subclasses that actually need it
    # select count distinct date, concat(client_id, enrollment_group_id, first_date_in_program)
    # from sh
    # where concat(client_id, enrollment_group_id, first_date_in_program)
    # group by (client_id, enrollment_group_id, first_date_in_program)
    def stay_length_for_adult_hoh(client_id:, entry_date:, enrollment_group_id:)
      @stay_lengths_for_adult_hohs ||= begin
        keys = adult_stayers_and_heads_of_household_stayers.map do |id, enrollment|
          [id, enrollment[:first_date_in_program], enrollment[:enrollment_group_id]]
        end
        lengths = {}
        keys.each_slice(10) do |clients|
          ors = clients.map do |client_id, entry_date, enrollment_id|
            sh_t[:client_id].eq(client_id).
              and(sh_t[:first_date_in_program].eq(entry_date).
              and(sh_t[:enrollment_group_id].eq(enrollment_id))
              ).to_sql
          end
          lengths.merge!(
            GrdaWarehouse::ServiceHistory.service.
              where(ors.join(' or ')).
              group(
                sh_t[:client_id],
                sh_t[:first_date_in_program],
                sh_t[:enrollment_group_id]
              ).pluck(
                nf('COUNT', [nf('DISTINCT', [sh_t[:date]])]).to_sql,
                :client_id,
                :first_date_in_program,
                :enrollment_group_id
            ).map do |count, client_id, entry_date, enrollment_id|
              [[client_id, entry_date, enrollment_id], count]
            end.to_h
          )
        end
        lengths
      end
      @stay_lengths_for_adult_hohs[[
        client_id,
        entry_date,
        enrollment_group_id
      ]] || 0      
    end

    def client_disabled?(enrollment)
      return true if enrollment[:DisablingCondition] == 1
      # load disabling conditions for client, we've indicated we don't have any.
      # If we do, we have a problem
      @client_disabilities ||= begin
        disabilities = [5,6,7,8,9]
        yes_responses = [1,2,3]
        disabled = {}
        @all_clients.keys.each_slice(5000) do |ids|
          ors = ids.map do |id|
            c_t[:id].eq(id).
              and(d_t[:DisabilityType].in(disabilities)).
              and(d_t[:DisabilityResponse].in(yes_responses)).to_sql
          end
          disabled.merge!(
            GrdaWarehouse::Hud::Client.joins(:source_disabilities).
              where(ors.join(' or ')).
              group(c_t[:id]).
              pluck(:id, nf('COUNT', [c_t[:id]]).to_sql).
              to_h
          )
        end
        disabled
      end
      @client_disabilities[enrollment[:client_id]].present? && @client_disabilities[enrollment[:client_id]] > 0
    end
    

    def living_situation_is_homeless? enrollment
      # [living situation] (3.917.1) = 16, 1, 18 or 27
      [16,1,18,27].include?(enrollment[:ResidencePrior]) ||
      # [on the night before, did you stay in streets, ES or SH?] (3.917.2c) 
      enrollment[:PreviousStreetESSH] == 1 ||
      # [project type] (2.4) = 1 or 4 or 8
      [1,4,8].include?(enrollment[:project_type])
    end

    def four_or_more_episodes_and_12_months_or_365_days? enrollment
      homeless_for_one_year?(enrollment) ||
      enrollment[:TimesHomelessPastThreeYears].present? && enrollment[:TimesHomelessPastThreeYears] >= 4 &&
       enrollment[:MonthsHomelessPastThreeYears].present? && enrollment[:MonthsHomelessPastThreeYears] >= 12
    end

    def debug
      Rails.env.development?
      # true
    end

    # just DRYing up some repetitive code to make the underlying pattern visible
    def columnize(pairs={})
      pairs.map{ |k, table| [ k.to_sym, table[k.to_sym].as(k.to_s).to_sql ] }.to_h
    end
  end
end