###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# require 'newrelic_rpm'
module ReportGenerators::DataQuality::Fy2017
  class Base
    ADULT = 18
    BATCH_SIZE = 250
    include ArelHelper
    include ApplicationHelper
    attr_reader :all_clients

    def initialize options
      @user = User.find(options[:user_id].to_i)
    end

    def add_filters scope:
      # Limit to only those projects the user who queued the report can see
      scope = scope.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(@report.user))

      project_group_ids = @report.options['project_group_ids'].delete_if(&:blank?).map(&:to_i)
      if project_group_ids.any?
        project_group_project_ids = GrdaWarehouse::ProjectGroup.where(id: project_group_ids).map(&:project_ids).flatten.compact
        @report.options['project_id'] |= project_group_project_ids
      end
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

    def all_client_scope
      @report_start ||= @report.options['report_start'].to_date
      @report_end ||= @report.options['report_end'].to_date
      client_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(@user)).
        open_between(start_date: @report_start,
          end_date: @report_end).
        joins(:client)

      add_filters(scope: client_scope)
    end

    def active_client_scope
      all_client_scope.service_within_date_range(start_date: @report_start,
        end_date: @report_end)
    end

    def leavers
      @report_start ||= @report.options['report_start'].to_date
      @report_end ||= @report.options['report_end'].to_date
      @leavers ||= begin
        # 1. A "system leaver" is any client who has exited from one or more of the relevant projects between [report start date] and [report end date] and who
        # is not active in any of the relevant projects as of the [report end date].
        # 2. The client must be an adult to be included.

        columns = {
          she_t[:client_id] => :client_id,
          she_t[:first_date_in_program] => :first_date_in_program,
          she_t[:last_date_in_program] => :last_date_in_program,
          she_t[:project_id] => :project_id,
          she_t[:age] => :age,
          c_t[:DOB] => :DOB,
          she_t[:enrollment_group_id] => :enrollment_group_id,
          she_t[:data_source_id] => :data_source_id,
          she_t[:project_tracking_method] => :project_tracking_method,
          she_t[:project_name] => :project_name,
          e_t[:RelationshipToHoH] => :RelationshipToHoH,
          she_t[:household_id] => :household_id,
          she_t[:destination] => :destination,

        }

        client_id_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          ongoing(on_date: @report_end)

        client_id_scope = add_filters(scope: client_id_scope)

        leavers_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          ended_between(start_date: @report_start,
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
          pluck(*columns.keys).map do |row|
            Hash[columns.values.zip(row)]
          end.group_by do |row|
            row[:client_id]
          end.map do |client_id, enrollments|
            # We only care about the last enrollment
            enrollment = enrollments.last
            enrollment[:age] = age_for_report(dob: enrollment[:DOB], enrollment: enrollment)
            [client_id, enrollment]
          end.to_h
      end
    end

    def stayers
      @report_end ||= @report.options['report_end'].to_date
      stayers ||= begin
        # 1. A "system stayer" is a client active in any one or more of the relevant projects as of the [report end date]. CoC Performance Measures Programming Specifications
        # 2. The client must have at least 365 days in latest stay to be included in this measure, using either bed-night or entry exit (you have to count the days)
        # 3. The client must be an adult to be included in this measure.

        columns = {
          she_t[:client_id] => :client_id,
          she_t[:first_date_in_program] => :first_date_in_program,
          she_t[:last_date_in_program] => :last_date_in_program,
          she_t[:project_id] => :project_id,
          she_t[:age] => :age,
          c_t[:DOB] => :DOB,
          she_t[:enrollment_group_id] => :enrollment_group_id,
          she_t[:data_source_id] => :data_source_id,
          she_t[:project_tracking_method] => :project_tracking_method,
          she_t[:project_name] => :project_name,
          e_t[:RelationshipToHoH] => :RelationshipToHoH,
          she_t[:household_id] => :household_id,
        }

        stayers_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          ongoing(on_date: @report_end).
          joins(:client, :enrollment)

        stayers_scope = add_filters(scope: stayers_scope)

        stayers_scope.
          order(client_id: :asc, first_date_in_program: :asc).
          pluck(*columns.keys).map do |row|
            Hash[columns.values.zip(row)]
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

    def adult_stayers
      @adult_stayers ||= stayers.select do |_, enrollment|
        adult?(enrollment[:age])
      end
    end

    def adult_stayers_and_heads_of_household_stayers
      @adult_stayers_and_heads_of_household_stayers ||= stayers.select do |_, enrollment|
        adult?(enrollment[:age]) || head_of_household?(enrollment[:RelationshipToHoH])
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
      age >= ADULT if age.present?
    end

    def child?(age)
      age < ADULT if age.present?
    end

    def head_of_household?(relationship)
      relationship.to_i == 1
    end

    def child_in_household?(relationship)
      relationship.to_i == 2
    end

    def valid_household_relationship?(relationship)
      (1..5).include?(relationship.to_i)
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
    def all_client_count
      count ||= @all_client_ids.size
    end

    def setup_age_categories(all_client_ids)
      @adults = {}
      @children = {}
      @unknown = {}
      all_client_ids.each_slice(250) do |client_ids|
        client_batch(client_ids).each do |client_id, enrollments|
          enrollment = enrollments.last
          age = enrollment[:age]
          if age.blank?
            @unknown[client_id] = age
          elsif adult?(age)
            @adults[client_id] = age
          elsif child?(age)
            @children[client_id] = age
          end
        end
      end
    end

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


    # create
    # [{
    #   <client_id>: {
    #     key: [ds_id, hh_id...],
    #     household: [enrollments]
    #   }
    # }]

    def household_columns
      @household_columns ||= {
        client_id: she_t[:client_id],
        DOB: c_t[:DOB],
        age: she_t[:age],
        project_id: she_t[:project_id],
        data_source_id: she_t[:data_source_id],
        first_date_in_program: she_t[:first_date_in_program],
        household_id: she_t[:household_id],
        RelationshipToHoH: e_t[:RelationshipToHoH],
      }
    end

    # Each client only gets one household, it is the household with their most
    # recent enrollment within the range
    def households
      @households ||= begin
        hh = {}

        # Individuals (no household id avaialble)
        client_batch_scope.
          where(household_id: [nil, '']).
          order(first_date_in_program: :asc).
          pluck(*household_columns.values).
          each do |row|
            enrollment = Hash[household_columns.keys.zip(row)]
            enrollment[:age] = age_for_report(dob: enrollment[:DOB], enrollment: enrollment)
            key = [
              enrollment[:data_source_id],
              enrollment[:project_id],
              enrollment[:household_id],
              enrollment[:first_date_in_program],
            ]
            hh[enrollment[:client_id]] = {
              key: key,
              household: [enrollment],
              first_date_in_program: enrollment[:first_date_in_program],
            }
          end

        # Households with potentially more than one client
        with_hhid_ids = client_batch_scope.
          where.not(household_id: [nil, '']).
          distinct.
          pluck(:household_id)

        with_hhid_ids.each_slice(250) do |batch|
          client_batch_scope.
            where(household_id: batch).
            order(first_date_in_program: :asc).
            pluck(*household_columns.values).
            map do |row|
              enrollment = Hash[household_columns.keys.zip(row)]
              enrollment[:age] = age_for_report(dob: enrollment[:DOB], enrollment: enrollment)
              enrollment
            end.group_by do |enrollment|
              [
                enrollment[:data_source_id],
                enrollment[:project_id],
                enrollment[:household_id],
                enrollment[:first_date_in_program],
              ]
            end.each do |key, enrollments|
              enrollments.each do |enrollment|
                existing_hh = hh[enrollment[:client_id]]
                next if existing_hh.present? && existing_hh[:first_date_in_program] > enrollment[:first_date_in_program]

                hh[enrollment[:client_id]] = {
                  key: key,
                  household: enrollments,
                  first_date_in_program: enrollment[:first_date_in_program],
                }
              end
            end
        end
        hh
      end
      @households
    end

    def adult_heads
      households.select do |id, household|
        household[:household].select do |member|
          adult?(member[:age]) && head_of_household?(member[:RelationshipToHoH])
        end.any?
      end
    end

    def other_heads
      households.select do |id, household|
        household[:household].select do |member|
          ! adult?(member[:age]) && head_of_household?(member[:RelationshipToHoH])
        end.any?
      end
    end

    def adult_leavers_and_heads_of_household_leavers
      @adult_head_leavers ||= leavers.select do |_, enrollment|
        adult?(enrollment[:age]) || head_of_household?(enrollment[:RelationshipToHoH])
      end
    end

    def adult_leavers
      @adult_leavers ||= leavers.select do |_, enrollment|
        adult?(enrollment[:age])
      end
    end

    def stay_length(client_id:, entry_date:, enrollment_group_id:)
      GrdaWarehouse::ServiceHistoryEnrollment.entry.
        where(
          client_id: client_id,
          first_date_in_program: entry_date,
          enrollment_group_id: enrollment_group_id
        ).joins(:service_history_services).
        select(shs_t[:date].to_sql).
        distinct.
        count
    end

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
            she_t[:client_id].eq(client_id).
              and(she_t[:first_date_in_program].eq(entry_date).
              and(she_t[:enrollment_group_id].eq(enrollment_id))
              ).to_sql
          end
          lengths.merge!(
            GrdaWarehouse::ServiceHistoryEnrollment.entry.
              joins(:service_history_services).
              where(ors.join(' or ')).
              group(
                she_t[:client_id],
                she_t[:first_date_in_program],
                she_t[:enrollment_group_id]
              ).pluck(
                nf('COUNT', [nf('DISTINCT', [shs_t[:date]])]).to_sql,
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

    def client_disabled?(enrollment:)
      return true if enrollment[:DisablingCondition] == 1
      # load disabling conditions for client, we've indicated we don't have any.
      # If we do, we have a problem
      @client_disabilities ||= begin
        disabilities = [5,6,7,8,9,10]
        yes_responses = [1,2,3]

        disabled = {}
        @all_client_ids.each_slice(5000) do |ids|
          ors = ids.map do |id|
            c_t[:id].eq(id).
              and(d_t[:DisabilityType].in(disabilities)).
              and(d_t[:DisabilityResponse].in(yes_responses)).
              and(d_t[:IndefiniteAndImpairs].eq(1)).to_sql
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


    def living_situation_is_homeless enrollment:
      # [living situation] (3.917.1) = 16, 1, 18 or 27
      [16,1,18,27].include?(enrollment[:LivingSituation]) ||
      # [on the night before, did you stay in streets, ES or SH?] (3.917.2c)
      enrollment[:PreviousStreetESSH] == 1 ||
      # [project type] (2.4) = 1 or 4 or 8
      [1,4,8].include?(enrollment[:project_type])
    end

    def homeless_for_one_year? enrollment:
      enrollment[:DateToStreetESSH].present? &&
      enrollment[:DateToStreetESSH].to_date <= (enrollment[:first_date_in_program] - 365.days)
    end

    def four_or_more_episodes_and_12_months_or_365_days? enrollment:
      homeless_for_one_year?(enrollment: enrollment) ||
      enrollment[:TimesHomelessPastThreeYears].present? && enrollment[:TimesHomelessPastThreeYears] >= 4 &&
       enrollment[:MonthsHomelessPastThreeYears].present? && enrollment[:MonthsHomelessPastThreeYears] >= 12
    end

    def personal_ids(destination_ids)
      GrdaWarehouse::WarehouseClient.
        where(destination_id: destination_ids).
        distinct.
        pluck(:destination_id, :id_in_source).
        group_by(&:first).transform_values{ |v| v.map(&:last).uniq }
    end

    def debug
      Rails.env.development?
      # true
    end

    def log_with_memory text
      # Rails.logger.info "#{text}: #{NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample} -- DQ DEBUG" if debug
    end

  end
end
