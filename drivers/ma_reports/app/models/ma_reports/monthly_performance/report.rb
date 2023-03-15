###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::MonthlyPerformance
  class Report < SimpleReports::ReportInstance
    include Rails.application.routes.url_helpers
    include ArelHelper
    include Reporting::Status
    include HudReports::Util
    include HudReports::Clients
    include HudReports::Ages
    include HudReports::Households
    include HudReports::LengthOfStays

    has_many :enrollments
    has_many :projects

    def run_and_save!
      start

      # Setup some household related data
      calculate_households
      create_universe
      # cache results
      demographic_breakdowns
      project_utilization_by_month
      # run!
      complete
    end

    def start
      update(started_at: Time.current)
    end

    def complete
      update(completed_at: Time.current)
    end

    def title
      'Project Utilization by Month'
    end

    def self.report_options
      [
        :start,
        :end,
        :project_ids,
        :age_ranges,
        :household_type,
        :hoh_only,
        :sub_population,
        :coc_codes,
        :project_type_numbers,
        :age_ranges,
        :data_source_ids,
        :organization_ids,
        :project_ids,
        :funder_ids,
        :project_group_ids,
        :cohort_ids,
      ].freeze
    end

    def filter
      @filter ||= begin
        f = ::Filters::FilterBase.new(user_id: user_id, enforce_one_year_range: false)
        f.update(options)
      end
    end

    def url
      ma_reports_warehouse_reports_monthly_project_utilization_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    private def create_universe
      # make create_universe repeatable for testing
      MaReports::MonthlyPerformance::Enrollment.where(report_id: id).delete_all
      MaReports::MonthlyPerformance::Project.where(report_id: id).delete_all
      SimpleReports::UniverseMember.where(report_cell_id: universe.id).delete_all
      projects = {}
      enrollment_scope.find_in_batches(batch_size: 100) do |batch|
        enrollment_batch = {}

        batch.each do |enrollment|
          next unless enrollment.enrollment.present?

          client = enrollment.client
          client_start_date = [filter.start_date, enrollment.first_date_in_program].max
          age = client.age_on(client_start_date)
          household_id = enrollment.enrollment.household_id || "#{enrollment.enrollment_group_id}*hh"
          project = enrollment.project
          cocs = project.project_cocs || project.build_project_coc

          cocs.each do |project_coc|
            ethnicity = nil
            ethnicity = client.ethnicity == 1 if client.ethnicity.in?([1, 0])
            new_enrollment = Enrollment.new(
              report_id: id,
              client_id: client.id,
              enrollment_id: enrollment.enrollment.id,
              project_id: project.id,
              project_coc_id: project_coc,
              personal_id: client.personal_id,
              city: project_coc.City,
              coc_code: project_coc.effective_coc_code,
              entry_date: enrollment.first_date_in_program,
              exit_date: enrollment.last_date_in_program,
              first_name: client.first_name,
              last_name: client.last_name,
              latest_for_client: enrollment.id == @last_enrollment_ids[enrollment.client_id],
              chronically_homeless_at_entry: enrollment.enrollment&.ch_enrollment&.chronically_homeless_at_entry,
              stay_length_in_days: stay_length(enrollment),
              am_ind_ak_native: client.am_ind_ak_native == 1,
              asian: client.asian == 1,
              black_af_american: client.black_af_american == 1,
              native_hi_pacific: client.native_hi_pacific == 1,
              white: client.white == 1,
              ethnicity: ethnicity,
              male: client.male == 1,
              female: client.female == 1,
              transgender: client.transgender == 1,
              questioning: client.questioning == 1,
              no_single_gender: client.no_single_gender == 1,
              disabling_condition: enrollment.enrollment.disabling_condition == 1,
              reporting_age: age,
              relationship_to_hoh: enrollment.enrollment.relationship_to_ho_h,
              household_id: household_id,
              household_type: household_makeup(get_hh_id(enrollment), enrollment.first_date_in_program),
              household_members: households[get_hh_id(enrollment)],
              prior_living_situation: enrollment.enrollment.living_situation,
              months_homeless_past_three_years: enrollment.enrollment.months_homeless_past_three_years,
              times_homeless_past_three_years: enrollment.enrollment.times_homeless_past_three_years,
            )
            # Collect up some project information so we don't have to go back for it
            projects[project] ||= {
              report_id: id,
              project_id: project.id,
              project_coc_id: project_coc.id,
              project_name: project.name,
              organization_name: project.organization_name,
              coc_code: project_coc.effective_coc_code,
              city: project_coc.city,
            }
            enrollment_batch[enrollment.id] = new_enrollment
          end
        end
        Enrollment.import(enrollment_batch.values)
        universe.add_universe_members(enrollment_batch)
      end

      Project.import(project_data(projects))
    end

    private def project_data(projects)
      monthly_projects = []
      a_t = MaReports::MonthlyPerformance::Enrollment.arel_table
      months.each do |month_start, month_end|
        projects.each do |project, project_data|
          available_beds = project.inventories.map { |i| i.average_daily_inventory(range: ::Filters::DateRange.new(start: month_start, end: month_end), field: :BedInventory) || 0 }.sum
          enrollments_for_project = universe.members.where(a_t[:project_id].eq(project.id)).
            merge(MaReports::MonthlyPerformance::Enrollment.open_between(month_start..month_end))
          length_of_stays_in_days = enrollments_for_project.pluck(:stay_length_in_days)
          number_chronically_homeless_at_entry = enrollments_for_project.where(a_t[:chronically_homeless_at_entry].eq(true)).count
          monthly_projects << project_data.merge(
            month_start: month_start,
            available_beds: available_beds,
            enrolled_client_count: length_of_stays_in_days.count,
            average_length_of_stay_in_days: average(length_of_stays_in_days.sum, length_of_stays_in_days.count),
            number_chronically_homeless_at_entry: number_chronically_homeless_at_entry,
          )
        end
      end
      monthly_projects
    end

    # Returns an array of months covered by the report in the form:
    # [['2021-05-01', '2021-05-31']]
    def months
      @months ||= [].tap do |dates|
        date = filter.start_date.beginning_of_month
        while date <= filter.end_date.end_of_month
          dates << [date, date.end_of_month]
          date += 1.months
        end
      end
    end

    def enrollment_scope
      enrollment_scope_without_preloads.
        preload(:client, enrollment: [:exit, :ch_enrollment, project: [:project_cocs, :inventories]])
    end

    def enrollment_scope_without_preloads
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry
      filter.apply(scope)
    end

    def average(value, count)
      return 0 unless count.positive?

      value.to_f / count
    end

    private def calculate_households
      @hoh_enrollments ||= {}
      @households ||= {}
      @last_enrollment_ids ||= {}

      enrollment_scope.find_in_batches(batch_size: 100) do |batch|
        clients_with_enrollments(batch).each do |client_id, enrollments|
          @last_enrollment_ids[client_id] ||= enrollments.last.id
          enrollments.each do |enrollment|
            @hoh_enrollments[enrollment.client_id] = enrollment if enrollment.head_of_household?
            next unless enrollment&.enrollment&.client.present?

            date = [enrollment.first_date_in_program, filter.start_date].max
            age = GrdaWarehouse::Hud::Client.age(date: date, dob: enrollment.enrollment.client.DOB&.to_date)
            @households[get_hh_id(enrollment)] ||= []
            @households[get_hh_id(enrollment)] << {
              client_id: enrollment.client_id,
              source_client_id: enrollment.enrollment.client.id,
              dob: enrollment.enrollment.client.DOB,
              age: age,
              veteran_status: enrollment.enrollment.client.VeteranStatus,
              chronic_status: enrollment.enrollment.chronically_homeless_at_start?,
              chronic_detail: enrollment.enrollment.chronically_homeless_at_start,
              relationship_to_hoh: enrollment.enrollment.RelationshipToHoH,
              # Include dates for determining if someone was present at assessment date
              entry_date: enrollment.first_date_in_program,
              exit_date: enrollment.last_date_in_program,
            }.with_indifferent_access
          end
        end
        GC.start
      end
    end

    private def clients_with_enrollments(batch)
      enrollment_scope.
        where(client_id: batch.map(&:client_id)).
        order(first_date_in_program: :asc).
        group_by(&:client_id).
        transform_values do |enrollments|
          enrollments.select do |enrollment|
            nbn_with_service?(enrollment)
          end
        end.
        reject { |_, enrollments| enrollments.empty? }
    end

    private def nbn_with_service?(enrollment)
      return true unless enrollment.nbn?

      @with_service ||= GrdaWarehouse::ServiceHistoryService.bed_night.
        service_excluding_extrapolated.
        service_within_date_range(start_date: filter.start_date, end_date: filter.end_date).
        where(service_history_enrollment_id: enrollment_scope_without_preloads.select(:id)).
        pluck(:service_history_enrollment_id).to_set

      @with_service.include?(enrollment.id)
    end

    def demographic_breakdowns
      Rails.cache.fetch([self.class.name, __method__, id], expires_in: 5.months) do
        key = ['All', nil]
        breakdowns = {
          'Unique Enrolled Clients' => {
            key: key,
            count: enrollments_for(*key).select(:client_id).distinct.count,
          },
        }
        HudUtility.races.each do |k, label|
          next if k == 'RaceNone'

          key = ['Race', k]
          breakdowns["Race: #{label}"] = {
            key: key,
            count: enrollments_for(*key).count,
          }
        end
        key = ['Ethnicity', 0]
        breakdowns['Ethnicity: Non-Hispanic/Non-Latin(a)(o)(x)'] = {
          key: key,
          count: enrollments_for(*key).count,
        }
        key = ['Ethnicity', 1]
        breakdowns['Ethnicity: Hispanic/Latin(a)(o)(x)'] = {
          key: key,
          count: enrollments_for(*key).count,
        }
        HudUtility.gender_id_to_field_name.
          reject { |k, _| k.in?([8, 9, 99]) }.
          each do |gender_id, gender_column|
            label = HudUtility.gender(gender_id)
            key = ['Gender', gender_column]
            breakdowns["Gender: #{label}"] = {
              key: key,
              count: enrollments_for(*key).count,
            }
          end
        key = ['DisablingCondition', nil]
        breakdowns['Disabling Condition'] = {
          key: key,
          count: enrollments_for(*key).count,
        }
        ::Filters::FilterBase.new(user_id: user_id).available_age_ranges.each do |label, k|
          key = ['Age', k]
          breakdowns["Age: #{label}"] = {
            key: key,
            count: enrollments_for(*key).count,
          }
        end
        HudUtility.valid_prior_living_situations.reject { |k, _| k.in?([8, 9, 99]) }.each do |k|
          key = ['PriorLivingSituation', k]
          breakdowns["Prior Living Situation: #{HudUtility.living_situation(k)}"] = {
            key: key,
            count: enrollments_for(*key).count,
          }
        end
        HudUtility.times_homeless_options.reject { |k, _| k.in?([8, 9, 99]) }.each do |k, label|
          key = ['TimesHomeless', k]
          breakdowns["Times Homeless in the past three years: #{label}"] = {
            key: key,
            count: enrollments_for(*key).count,
          }
        end
        HudUtility.month_categories.reject { |k, _| k.in?([8, 9, 99]) }.each do |k, label|
          key = ['MonthsHomeless', k]
          breakdowns["Months homeless in the past 3 years: #{label}"] = {
            key: key,
            count: enrollments_for(*key).count,
          }
        end
        breakdowns
      end
    end

    def enrollments_for(key, sub_key)
      case key
      when 'All'
        enrollments
      when 'Race'
        return enrollments.none unless HudUtility.races.key?(sub_key)

        enrollments.where(sub_key.underscore => true)
      when 'Ethnicity'
        return enrollments.none unless HudUtility.ethnicities.key?(sub_key.to_i)

        enrollments.where(ethnicity: sub_key.to_i)
      when 'Gender'
        return enrollments.none unless HudUtility.genders.key?(sub_key)

        enrollments.where(sub_key.underscore => true)
      when 'DisablingCondition'
        enrollments.where(disabling_condition: true)
      when 'Age'
        return enrollments.none unless ::Filters::FilterBase.new(user_id: user_id).available_age_ranges.value?(sub_key.to_sym)

        enrollments.where(reporting_age: ::Filters::FilterBase.age_range(sub_key.to_sym))
      when 'PriorLivingSituation'
        return enrollments.none unless HudUtility.valid_prior_living_situations.include?(sub_key.to_i)

        enrollments.where(prior_living_situation: sub_key)
      when 'TimesHomeless'
        return enrollments.none unless HudUtility.times_homeless_options.key?(sub_key.to_i)

        enrollments.where(times_homeless_past_three_years: sub_key)
      when 'MonthsHomeless'
        return enrollments.none unless HudUtility.month_categories.key?(sub_key.to_i)

        enrollments.where(months_homeless_past_three_years: sub_key)
      else
        return enrollments.none
      end
    end

    def title_for(key, sub_key)
      case key
      when 'All'
        'Unique Enrolled Clients'
      when 'Race'
        label = HudUtility.race(sub_key)
        "#{key}: #{label}"
      when 'Ethnicity'
        label = HudUtility.ethnicity(sub_key.to_i)
        "#{key}: #{label}"
      when 'Gender'
        label = HudUtility.gender(sub_key.to_i)
        "#{key}: #{label}"
      when 'DisablingCondition'
        'Disabling Condition'
      when 'Age'
        label = ::Filters::FilterBase.new(user_id: user_id).available_age_ranges.invert[sub_key.to_sym]
        "#{key}: #{label}"
      when 'PriorLivingSituation'
        label = HudUtility.living_situation(sub_key.to_i)
        "#{key}: #{label}"
      when 'TimesHomeless'
        label = HudUtility.times_homeless_past_three_years(sub_key.to_i)
        "#{key}: #{label}"
      when 'MonthsHomeless'
        label = HudUtility.months_homeless_past_three_years(sub_key.to_i)
        "#{key}: #{label}"
      end
    end

    def project_utilization_by_month
      Rails.cache.fetch([self.class.name, __method__, id], expires_in: 5.months) do
        rows = [['Month Start', 'CoC', 'City', 'Organization', 'Project', 'Active Enrollments', 'Average Daily Available Beds', 'Average Length of Stay (months)', 'Number of Chronically Homeless Individuals Served (at entry)']]
        projects.each do |project|
          rows << [
            project.month_start,
            project.coc_code,
            project.city,
            project.organization_name,
            project.project_name,
            project.enrolled_client_count,
            project.available_beds,
            project.average_length_of_stay_in_days / 30,
            project.number_chronically_homeless_at_entry,
          ]
        end
        rows
      end
    end

    def report_end_date
      filter.end_date
    end

    def key_for_display(key)
      case key
      when 'data_source_ids'
        'Data Sources'
      when 'project_ids'
        'Projects'
      when 'organization_ids'
        'Organizations'
      else
        key.humanize.titleize
      end
    end

    def value_for_display(key, value)
      value = case key
      when 'user_id'
        User.find_by(id: value)&.name
      when 'sub_population'
        GrdaWarehouse::WarehouseReports::Dashboard::Base.available_sub_populations.invert[value.to_sym]
      when 'data_source_ids'
        GrdaWarehouse::DataSource.where(id: value).map(&:short_name)
      when 'project_ids'
        # We can ignore confidential status here because this renders the selected project list,
        # and confidential projects are only selectable for users who can view their names.
        GrdaWarehouse::Hud::Project.where(id: value).map { |project| project.name_and_type(ignore_confidential_status: true) }
      when 'organization_ids'
        GrdaWarehouse::Hud::Organization.where(id: value).map(&:OrganizationName)
      else
        value
      end
      return value unless value.is_a?(Array)

      text = value[0...5].to_sentence(last_word_connector: ', ').to_s
      text += ', ...' if value.count > 5
      text
    end
  end
end
