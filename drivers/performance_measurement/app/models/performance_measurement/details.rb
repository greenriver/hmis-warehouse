###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement::Details
  extend ActiveSupport::Concern

  included do
    def summary_table
      @summary_table ||= {}.tap do |st|
        detail_hash.each do |key, data|
          st[data[:category]] ||= {}
          st[data[:category]][data[:sub_category]] ||= {}
          st[data[:category]][data[:sub_category]][key] = data
        end
      end
    end

    def detail_title_for(key)
      detail_hash[key][:title]
    end

    def detail_category_for(key)
      detail_hash[key][:category]
    end

    def goal_configurations
      @goal_configurations ||= {}.tap do |gc|
        detail_hash.each do |_key, data|
          gc[data[:category]] ||= {}
          gc[data[:category]][data[:sub_category]] ||= {}
          gc[data[:category]][data[:sub_category]][data[:goal_calculation]] ||= []
          gc[data[:category]][data[:sub_category]][data[:goal_calculation]] << [
            data[:title],
            data[:goal_description],
          ]
        end
      end
    end

    def highlight_id(category)
      {
        'rare' => 1,
        'brief' => 2,
        'non-recurring' => 3,
      }[category.downcase]
    end

    def detail_goal_description_for(key)
      detail = detail_hash[key]
      format(detail[:goal_description], { goal: goal_config[detail[:goal_calculation]] })
    end

    def detail_calculation_description_for(key)
      detail_hash[key][:calculation_description]
    end

    def detail_column_for(key)
      detail_hash[key][:column]
    end

    def detail_denominator_label_for(key)
      detail_hash[key][:denominator_label]
    end

    def my_projects(user, key)
      project_details(key).select do |project_id, _|
        user.viewable_project_ids.include?(project_id)
      end
    end
    memoize :my_projects

    def other_projects(user, key)
      project_details(key).select do |project_id, _|
        user.viewable_project_ids.exclude?(project_id)
      end
    end
    memoize :other_projects

    def project_details(key)
      details = results.project.left_outer_joins(:hud_project).
        order(p_t[:ProjectName].asc, p_t[GrdaWarehouse::Hud::Project.project_type_column].asc).
        for_field(key).
        sort_by { |project| project.hud_project.name_and_type }.
        index_by(&:project_id)
      # throw out any where there are no associated client_projects
      cp_key = detail_hash[key][:calculation_column]
      project_ids = client_projects.for_question(cp_key).distinct.pluck(:project_id)
      details.select { |k, _| k.in?(project_ids) }.to_h
    end
    memoize :project_details

    def clients_for_question(key, period, project_id: nil)
      field = result_methods[key]
      return [] unless field

      project_scope = PerformanceMeasurement::ClientProject.where(period: period, for_question: field)
      project_scope = project_scope.where(project_id: project_id.to_i) if project_id
      clients.joins(:client_projects).merge(project_scope)
    end
    memoize :clients_for_question

    private def detail_hash
      @detail_hash ||= {
        count_of_homeless_clients: {
          category: 'Rare',
          sub_category: 'People',
          column: :both,
          title: 'Number of Homeless People at PIT Count',
          goal_description: 'The CoC will reduce total homelessness by %{goal}%% annually (as reported during a single Point in Time)',
          goal_calculation: :people,
          denominator_label: '',
          calculation_description: 'The difference (as a percentage) between the total number of sheltered and unsheltered homeless reported in the most recent annual PIT Count and the total sheltered and unsheltered homeless reported in the previous year’s PIT Count',
          calculation_column: :served_on_pit_date,
          detail_columns: [
            'served_on_pit_date',
            'served_on_pit_date_sheltered',
            'served_on_pit_date_unsheltered',
          ],
        },
        count_of_sheltered_homeless_clients: {
          category: 'Rare',
          sub_category: 'People',
          column: :both,
          title: 'Number of Sheltered Homeless People',
          goal_description: 'The CoC will reduce total counts of sheltered homeless in HMIS by %{goal}%% annually',
          goal_calculation: :people,
          denominator_label: '',
          calculation_description: 'The difference (as a percentage) between the number of un-duplicated total sheltered homeless persons reported in HMIS (via ES and TH projects) and the previous reporting period’s count',
          calculation_column: :served_on_pit_date_sheltered,
          detail_columns: [
            'served_on_pit_date',
            'served_on_pit_date_sheltered',
            'served_on_pit_date_unsheltered',
          ],
        },
        count_of_unsheltered_homeless_clients: {
          category: 'Rare',
          sub_category: 'People',
          column: :both,
          title: 'Number of Unsheltered Homeless People',
          goal_description: 'The CoC will reduce total counts of unsheltered homeless in HMIS by %{goal}%% annually',
          goal_calculation: :people,
          denominator_label: '',
          calculation_description: 'The difference (as a percentage) between the number of un-duplicated total unsheltered homeless persons reported in HMIS (via SO projects) and the previous reporting period’s count',
          calculation_column: :served_on_pit_date_unsheltered,
          detail_columns: [
            'served_on_pit_date',
            'served_on_pit_date_sheltered',
            'served_on_pit_date_unsheltered',
          ],
        },
        first_time_homeless_clients: {
          category: 'Rare',
          sub_category: 'People',
          column: :both,
          title: 'Number of First-Time Homeless People',
          goal_description: 'The CoC will reduce total counts of persons experiencing homelessness for the first time in HMIS by %{goal}%% annually',
          goal_calculation: :people,
          denominator_label: '',
          calculation_description: 'The difference (as a percentage) between the number of persons who entered during the reporting period with no prior enrollments in  HMIS (via the CoC’s ES, SH, TH, and PH projects) and the previous reporting period’s count.',
          calculation_column: :first_time,
          detail_columns: [
            'first_time',
          ],
        },
        overall_average_bed_utilization: {
          category: 'Rare',
          sub_category: 'Capacity',
          column: :system,
          title: 'Average Bed Utilization Overall',
          goal_description: 'The CoC will maintain utilization rates higher than %{goal}%%.',
          goal_calculation: :capacity,
          denominator_label: 'Average Capacity',
          calculation_description: 'The average of the number of persons occupying a bed each night divided by the system’s total bed capacity during the reporting range.',
          calculation_column: :days_in_th_bed_in_period,
          detail_columns: [
            'days_in_es_bed_in_period',
            'days_in_sh_bed_in_period',
            'days_in_th_bed_in_period',
          ],
        },
        es_average_bed_utilization: {
          category: 'Rare',
          sub_category: 'Capacity',
          column: :both,
          title: 'Average Bed Utilization in ES',
          goal_description: 'The CoC will maintain utilization rates higher than %{goal}%%.',
          goal_calculation: :capacity,
          denominator_label: 'Average Capacity',
          calculation_description: 'The average of the number of persons occupying a bed each night divided by the system’s total bed capacity for Emergency Shelter during the reporting range.',
          calculation_column: :days_in_es_bed_in_period,
          detail_columns: [
            'days_in_es_bed_in_period',
          ],
        },
        sh_average_bed_utilization: {
          category: 'Rare',
          sub_category: 'Capacity',
          column: :both,
          title: 'Average Bed Utilization in SH',
          goal_description: 'The CoC will maintain utilization rates higher than %{goal}%%.',
          goal_calculation: :capacity,
          denominator_label: 'Average Capacity',
          calculation_description: 'The average of the number of persons occupying a bed each night divided by the system’s total bed capacity for Safe Haven during the reporting range.',
          calculation_column: :days_in_sh_bed_in_period,
          detail_columns: [
            'days_in_sh_bed_in_period',
          ],
        },
        th_average_bed_utilization: {
          category: 'Rare',
          sub_category: 'Capacity',
          column: :both,
          title: 'Average Bed Utilization in TH',
          goal_description: 'The CoC will maintain utilization rates higher than %{goal}%%.',
          goal_calculation: :capacity,
          denominator_label: 'Average Capacity',
          calculation_description: 'The average of the number of persons occupying a bed each night divided by the system’s total bed capacity for Transitional Housing during the reporting range.',
          calculation_column: :days_in_th_bed_in_period,
          detail_columns: [
            'days_in_th_bed_in_period',
          ],
        },
        length_of_homeless_time_homeless_average: {
          category: 'Brief',
          sub_category: 'Time',
          column: :system,
          title: 'Length of Time Homeless (Average Days)',
          goal_description: 'Persons in the CoC will have an average combined length of time homeless of no more than %{goal} days.',
          goal_calculation: :time_time,
          denominator_label: '',
          calculation_description: 'SPM 1a. Average number of days persons are homeless in ES, SH, and TH projects.',
          calculation_column: :days_homeless_es_sh_th,
          detail_columns: [
            'days_homeless_es_sh_th',
          ],
        },
        length_of_homeless_time_homeless_median: {
          category: 'Brief',
          sub_category: 'Time',
          column: :system,
          title: 'Length of Time Homeless (Median Days)',
          goal_description: 'Persons in the CoC will have a median combined length of time homeless of no more than %{goal} days.',
          goal_calculation: :time_time,
          denominator_label: '',
          calculation_description: 'SPM 1a. Median number of days persons are homeless in ES, SH, and TH projects.',
          calculation_column: :days_homeless_es_sh_th,
          detail_columns: [
            'days_homeless_es_sh_th',
          ],
        },
        length_of_homeless_stay_average: {
          category: 'Brief',
          sub_category: 'Time',
          column: :project,
          title: 'Length of Homeless Stay (Average Days)',
          goal_description: 'Persons in the CoC will have an average combined length of time homeless of no more than %{goal} days.',
          goal_calculation: :time_stay,
          denominator_label: '',
          calculation_description: 'A count of unique dates homeless.',
          calculation_column: :days_in_homeless_bed,
          detail_columns: [
            'days_in_homeless_bed',
            'days_in_homeless_bed_details',
            'days_in_homeless_bed_in_period',
            'days_in_homeless_bed_details_in_period',
            'days_in_es_bed',
            'days_in_sh_bed',
            'days_in_so_bed',
            'days_in_th_bed',
            'days_in_es_bed_details',
            'days_in_sh_bed_details',
            'days_in_so_bed_details',
            'days_in_th_bed_details',
            'days_in_es_bed_in_period',
            'days_in_sh_bed_in_period',
            'days_in_so_bed_in_period',
            'days_in_th_bed_in_period',
            'days_in_es_bed_details_in_period',
            'days_in_sh_bed_details_in_period',
            'days_in_so_bed_details_in_period',
            'days_in_th_bed_details_in_period',
          ],
        },
        length_of_homeless_stay_median: {
          category: 'Brief',
          sub_category: 'Time',
          column: :project,
          title: 'Length of Homeless Stay (Median Days)',
          goal_description: 'Persons in the CoC will have a median combined length of time homeless of no more than %{goal} days.',
          goal_calculation: :time_stay,
          denominator_label: '',
          calculation_description: 'A count of unique dates homeless.',
          calculation_column: :days_in_homeless_bed,
          detail_columns: [
            'days_in_homeless_bed',
            'days_in_homeless_bed_details',
            'days_in_homeless_bed_in_period',
            'days_in_homeless_bed_details_in_period',
            'days_in_es_bed',
            'days_in_sh_bed',
            'days_in_so_bed',
            'days_in_th_bed',
            'days_in_es_bed_details',
            'days_in_sh_bed_details',
            'days_in_so_bed_details',
            'days_in_th_bed_details',
            'days_in_es_bed_in_period',
            'days_in_sh_bed_in_period',
            'days_in_so_bed_in_period',
            'days_in_th_bed_in_period',
            'days_in_es_bed_details_in_period',
            'days_in_sh_bed_details_in_period',
            'days_in_so_bed_details_in_period',
            'days_in_th_bed_details_in_period',
          ],
        },
        time_to_move_in_average: {
          category: 'Brief',
          sub_category: 'Time to Move-in',
          column: :system,
          title: 'Time to Move-in (Average Days)',
          goal_description: 'Persons in the CoC will have an average combined length of time homeless of no more than %{goal} days.',
          goal_calculation: :time_move_in,
          denominator_label: '',
          calculation_description: 'SPM 1b. Average number of days persons report being homeless prior to entering ES, SH, TH and PH projects, plus the time spent in those projects prior to Housing Move-In Date (as appliable).',
          calculation_column: :days_homeless_es_sh_th_ph,
          detail_columns: [
            'days_homeless_es_sh_th_ph',
          ],
        },
        time_to_move_in_median: {
          category: 'Brief',
          sub_category: 'Time to Move-in',
          column: :system,
          title: 'Time to Move-in (Median Days)',
          goal_description: 'Persons in the CoC will have a median combined length of time homeless of no more than %{goal} days.',
          goal_calculation: :time_move_in,
          denominator_label: '',
          calculation_description: 'SPM 1b. Median number of days persons report being homeless prior to entering ES, SH, TH and PH projects, plus the time spent in those projects prior to Housing Move-In Date (as appliable).',
          calculation_column: :days_homeless_es_sh_th_ph,
          detail_columns: [
            'days_homeless_es_sh_th_ph',
          ],
        },
        so_positive_destinations: {
          category: 'Non-Recurring',
          sub_category: 'Destination',
          column: :both,
          title: 'Number of People Exiting SO to a Positive Destination',
          goal_description: 'At least %{goal}%% of persons in SO will exit to a “positive” destination (as defined by HUD)',
          goal_calculation: :destination,
          denominator_label: 'Total Exits',
          calculation_description: 'Number of persons who exited street outreach to a positive destination / Number of persons who exited street outreach.',
          calculation_column: :so_destination_positive,
          detail_columns: [
            'so_destination',
          ],
        },
        es_sh_th_rrh_positive_destinations: {
          category: 'Non-Recurring',
          sub_category: 'Destination',
          column: :both,
          title: 'Number of People Exits from ES, SH, TH, RRH to a Positive Destination, or PH with No Move-in',
          goal_description: 'At least %{goal}%% of persons housed in ES, SH, TH, and RRH projects will move into permanent housing at exit',
          goal_calculation: :destination,
          denominator_label: 'Total Exits',
          calculation_description: 'Number of persons who exited to permanent housing destination / Number of persons who exited ES, SH, TH, RRH, plus persons in other PH projects who exited without moving into housing',
          calculation_column: :es_sh_th_rrh_destination_positive,
          detail_columns: [
            'es_sh_th_rrh_destination',
          ],
        },
        moved_in_positive_destinations: {
          category: 'Non-Recurring',
          sub_category: 'Destination',
          column: :both,
          title: 'Number of People in RRH or PH with Move-in or Permanent Exit',
          goal_description: 'At least %{goal}%% of persons remain housed in PH projects or exit to a permanent housing destination',
          goal_calculation: :destination,
          denominator_label: 'Total Exits/Move-ins',
          calculation_description: 'Number of persons with a Housing Move-In Date that either exited to a permanent destination after moving into housing or remained in the PH project / Number of persons housed by PH projects',
          calculation_column: :moved_in_destination_positive,
          detail_columns: [
            'moved_in_destination',
          ],
        },
        returned_in_six_months: {
          category: 'Non-Recurring',
          sub_category: 'Recidivism',
          column: :both,
          title: 'Number of People Who Returned to Homelessness Within Six Months',
          goal_description: 'The CoC will have no more than %{goal}%% of adults who exited to permanent housing return to ES, SH, TH, or SO within six months of exit',
          goal_calculation: :recidivism_6_months,
          denominator_label: 'Total Returns',
          calculation_description: 'Based on clients who exited SO, ES, TH, SH, or PH to a permanent housing destination in the date range two years prior to the report date range: Number of persons who returned to SO, ES, TH, SH or PH within 6 months of exit / Number of persons who exited SO, ES, TH, SH, or PH to a permanent housing destination in the date range two years prior to the report date range',
          calculation_column: :returned_in_six_months,
          detail_columns: [
            'days_to_return',
          ],
        },
        returned_in_two_years: {
          category: 'Non-Recurring',
          sub_category: 'Recidivism',
          column: :both,
          title: 'Number of People Who Returned to Homelessness Within Two Years',
          goal_description: 'The CoC will have no more than %{goal}%% of adults who exited to permanent housing return to ES, SH, TH, or Outreach within two years of exit',
          goal_calculation: :recidivism_24_months,
          denominator_label: 'Total Returns',
          calculation_description: 'Based on clients who exited SO, ES, TH, SH, or PH to a permanent housing destination in the date range two years prior to the report date range: Number of persons who returned to SO, ES, TH, SH or PH within 2 years of exit / Number of persons who exited SO, ES, TH, SH, or PH to a permanent housing destination in the date range two years prior to the report date range',
          calculation_column: :returned_in_two_years,
          detail_columns: [
            'days_to_return',
          ],
        },
        stayers_with_increased_income: {
          category: 'Non-Recurring',
          sub_category: 'Income',
          column: :both,
          title: 'Stayer With Increased Income',
          goal_description: 'CoC-funded projects will increase the percentage of adult leavers who increase total income by %{goal}%% annually',
          goal_calculation: :income,
          denominator_label: 'Total Stayers',
          calculation_description: 'Number of adult stayers in CoC-funded projects with increased total income / Number of adult system stayers in CoC-funded projects',
          calculation_column: :increased_income__income_stayer,
          detail_columns: [
            'income_stayer',
            'increased_income',
          ],
        },
        leavers_with_increased_income: {
          category: 'Non-Recurring',
          sub_category: 'Income',
          column: :both,
          title: 'Leaver With Increased Income',
          goal_description: 'CoC-funded projects will increase the percentage of adult stayers who increase total income by %{goal}%% annually',
          goal_calculation: :income,
          denominator_label: 'Total Leavers',
          calculation_description: 'Number of adult leavers from CoC-funded projects with increased total income / Number of adult system leavers from CoC-funded projects',
          calculation_column: :increased_income__income_leaver,
          detail_columns: [
            'income_leaver',
            'increased_income',
          ],
        },
      }
    end

    private def detail_columns_for(key:, period: 'reporting')
      detail_hash[key.to_sym][:detail_columns].map do |col|
        "#{period}_#{col}"
      end
    end

    def detail_headers(key:, period: 'reporting')
      columns = [
        'client_id',
        'dob',
        'veteran',
        "#{period}_age",
        "#{period}_hoh",
        "#{period}_current_project_types",
        "#{period}_prior_project_types",
        "#{period}_prior_living_situation",
        "#{period}_destination",
      ] + detail_columns_for(key: key, period: period)
      PerformanceMeasurement::Client.column_titles(period: period).select { |k, _| k.to_s.in?(columns) }.to_h
    end
  end
end
