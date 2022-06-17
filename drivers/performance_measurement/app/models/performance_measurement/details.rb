###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

    def detail_year_over_year_change?(key)
      detail_hash[key][:year_over_year_change]
    end

    def detail_current_value_relevant?(key)
      detail_hash[key][:current_value_relevant]
    end

    def detail_goal_description_for(key)
      detail = detail_hash[key]
      format(detail[:goal_description], { goal: goal_config[detail[:goal_calculation]] })
    end

    def detail_goal_for_reference_line(key)
      # Only show goal for reference line if units match
      detail = detail_hash[key]
      goal_value = goal_config[detail[:goal_calculation]]
      goal_is_percentage = detail[:goal_description].include? '%{goal}%%'
      value_is_percentage = detail[:denominator_label].present?
      return nil unless goal_is_percentage == value_is_percentage

      goal_value
    end

    def detail_calculation_description_for(key)
      detail_hash[key][:calculation_description]
    end

    def detail_measure_for(key)
      detail_hash[key][:measure]
    end

    def detail_column_for(key)
      detail_hash[key][:column]
    end

    def detail_denominator_label_for(key)
      detail_hash[key].try(:[], :denominator_label)&.downcase || ''
    end

    def detail_numerator_label_for(key)
      detail_hash[key].try(:[], :numerator_label)&.downcase || ''
    end

    def my_projects(user, key)
      project_details(key).select do |project_id, _|
        user.viewable_project_ids.include?(project_id)
      end
    end
    memoize :my_projects

    def detail_indicator_result(result, key)
      return result unless detail_year_over_year_change?(key)

      adjusted_result = result.dup
      adjusted_result.primary_value = result.secondary_value
      adjusted_result.primary_unit = "#{result.secondary_unit} #{result.value_label}"
      adjusted_result.secondary_value = result.primary_value
      adjusted_result.secondary_unit = result.primary_unit
      adjusted_result.value_label = nil
      adjusted_result
    end

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
      field = detail_hash[key].try(:[], :calculation_column)
      return [] unless field

      project_scope = PerformanceMeasurement::ClientProject.where(period: period, for_question: field)
      project_scope = project_scope.where(project_id: project_id.to_i) if project_id
      clients.joins(:client_projects).merge(project_scope)
    end
    memoize :clients_for_question

    def display_order
      [
        [
          {
            count_of_homeless_clients: [],
            count_of_homeless_clients_in_range: [
              :count_of_sheltered_homeless_clients,
              :count_of_unsheltered_homeless_clients,
            ],
            first_time_homeless_clients: [],
          },
          {
            overall_average_bed_utilization: [
              :es_average_bed_utilization,
              :sh_average_bed_utilization,
              :th_average_bed_utilization,
              :rrh_average_bed_utilization,
              :psh_average_bed_utilization,
              :oph_average_bed_utilization,
            ],
          },
        ],
        [
          {
            length_of_homeless_time_homeless_average: [],
            length_of_homeless_stay_average: [],
            time_to_move_in_average: [],
          },
        ],
        [
          {
            retention_or_positive_destinations: [
              :so_positive_destinations,
              :es_sh_th_rrh_positive_destinations,
              :moved_in_positive_destinations,
            ],
          },
          {
            returned_in_two_years: [
              :returned_in_six_months,
            ],
          },
          {
            increased_income_all_clients: [
              :stayers_with_increased_income,
              :stayers_with_increased_earned_income,
              :stayers_with_increased_non_cash_income,
              :leavers_with_increased_income,
              :leavers_with_increased_earned_income,
              :leavers_with_increased_non_cash_income,
            ],
          },
        ],
      ]
    end

    # Some fields should only be displayed if there are projects of that type included in the report scope
    def show_row?(key)
      return true unless limit_display_by_project_type.key?(key)

      projects.joins(:hud_project).merge(GrdaWarehouse::Hud::Project.send(limit_display_by_project_type[key])).exists?
    end

    private def limit_display_by_project_type
      {
        es_average_bed_utilization: :es,
        sh_average_bed_utilization: :sh,
        th_average_bed_utilization: :th,
        rrh_average_bed_utilization: :rrh,
        psh_average_bed_utilization: :psh,
        oph_average_bed_utilization: :oph,
      }
    end

    def detail_hash
      @detail_hash ||= {
        count_of_homeless_clients: {
          category: 'Rare',
          sub_category: 'Homelessness',
          column: :both,
          year_over_year_change: true,
          title: "Number of Homeless People Seen on #{filter.pit_date}",
          goal_description: 'The CoC will reduce total homelessness by **%{goal}%% annually** (as reported during a single Point in Time)',
          goal_calculation: :people,
          denominator_label: '',
          calculation_description: 'The difference (as a percentage) between the total number of persons who are sheltered and unsheltered homeless and seen by ES, TH and SO on the last Wednesday of January within the report range and the last Wednesday of January in the comparison range.',
          calculation_column: :served_on_pit_date,
          detail_columns: [
            'served_on_pit_date',
            'served_on_pit_date_sheltered',
            'served_on_pit_date_unsheltered',
          ],
        },
        count_of_homeless_clients_in_range: {
          category: 'Rare',
          sub_category: 'Homelessness',
          column: :system,
          year_over_year_change: true,
          title: 'Number of Homeless People Seen Throughout the Year',
          goal_description: 'The CoC will reduce total homelessness by **%{goal}%% annually**',
          goal_calculation: :people,
          denominator_label: '',
          calculation_description: 'The difference (as a percentage) between the total number of persons who are sheltered and unsheltered homeless and seen within the report range and comparison range.',
          calculation_column: :seen_in_range,
          detail_columns: [
            'served_on_pit_date_sheltered',
            'served_on_pit_date_unsheltered',
          ],
        },
        count_of_sheltered_homeless_clients: {
          category: 'Rare',
          sub_category: 'Homelessness',
          column: :both,
          year_over_year_change: true,
          title: 'Number of Sheltered Homeless People',
          goal_description: 'The CoC will reduce total counts of sheltered homeless in HMIS by **%{goal}%% annually**',
          goal_calculation: :people,
          denominator_label: '',
          calculation_description: 'The difference (as a percentage) between the total unduplicated number of persons who are sheltered homeless as reported in HMIS (in ES and TH projects) and seen within the report range and comparison range.',
          calculation_column: :served_on_pit_date_sheltered,
          measure: 'Measure 3',
          detail_columns: [
            'served_on_pit_date',
            'served_on_pit_date_sheltered',
            'served_on_pit_date_unsheltered',
          ],
        },
        count_of_unsheltered_homeless_clients: {
          category: 'Rare',
          sub_category: 'Homelessness',
          column: :both,
          year_over_year_change: true,
          title: 'Number of Unsheltered Homeless People',
          goal_description: 'The CoC will reduce total counts of unsheltered homeless in HMIS by **%{goal}%% annually**',
          goal_calculation: :people,
          denominator_label: '',
          calculation_description: 'The difference (as a percentage) between the total unduplicated number of persons who are unsheltered homeless as reported in HMIS (via SO projects) and seen within the report range and comparison range.',
          calculation_column: :served_in_range_unsheltered,
          detail_columns: [
            'served_on_pit_date',
            'served_on_pit_date_sheltered',
            'served_in_range_unsheltered',
          ],
        },
        first_time_homeless_clients: {
          category: 'Rare',
          sub_category: 'Homelessness',
          column: :both,
          year_over_year_change: true,
          title: 'Number of First-Time Homeless People',
          goal_description: 'The CoC will reduce total counts of persons experiencing homelessness for the first time in HMIS by **%{goal}%% annually**',
          goal_calculation: :people,
          denominator_label: '',
          calculation_description: 'The difference (as a percentage) between the number of persons who entered a homeless project with no prior enrollments in HMIS (via the CoC\'s ES, SH, TH, and PH projects) during the reporting range and comparison range.',
          calculation_column: :first_time,
          measure: 'Measure 5',
          detail_columns: [
            'first_time',
          ],
        },
        overall_average_bed_utilization: {
          category: 'Rare',
          sub_category: 'Capacity',
          column: :system,
          year_over_year_change: false,
          title: 'Average Bed Utilization Overall',
          goal_description: 'The CoC will maintain utilization rates **higher than %{goal}%%**.',
          goal_calculation: :capacity,
          denominator_label: 'Average Capacity',
          calculation_description: 'The average number of persons occupying a bed each night divided by the system’s total bed capacity during the reporting range',
          calculation_column: :days_in_any_bed_in_period,
          detail_columns: [
            'days_in_es_bed_in_period',
            'days_in_sh_bed_in_period',
            'days_in_th_bed_in_period',
            'days_in_rrh_bed_in_period',
            'days_in_psh_bed_in_period',
            'days_in_oph_bed_in_period',
          ],
        },
        es_average_bed_utilization: {
          category: 'Rare',
          sub_category: 'Capacity',
          column: :both,
          year_over_year_change: false,
          title: 'Average Bed Utilization in ES',
          goal_description: 'The CoC will maintain Emergency Shelter utilization rates **higher than %{goal}%%**.',
          goal_calculation: :capacity,
          denominator_label: 'Average Capacity',
          calculation_description: 'The average number of persons occupying a bed each night divided by the system\'s total bed capacity for Emergency Shelter during the reporting range.',
          calculation_column: :days_in_es_bed_in_period,
          detail_columns: [
            'days_in_es_bed_in_period',
          ],
        },
        sh_average_bed_utilization: {
          category: 'Rare',
          sub_category: 'Capacity',
          column: :both,
          year_over_year_change: false,
          title: 'Average Bed Utilization in SH',
          goal_description: 'The CoC will maintain Safe Haven utilization rates **higher than %{goal}%%**.',
          goal_calculation: :capacity,
          denominator_label: 'Average Capacity',
          calculation_description: 'The average number of persons occupying a bed each night divided by the system\'s total bed capacity for Safe Haven during the reporting range.',
          calculation_column: :days_in_sh_bed_in_period,
          detail_columns: [
            'days_in_sh_bed_in_period',
          ],
        },
        th_average_bed_utilization: {
          category: 'Rare',
          sub_category: 'Capacity',
          column: :both,
          year_over_year_change: false,
          title: 'Average Bed Utilization in TH',
          goal_description: 'The CoC will maintain Transitional Housing utilization rates **higher than %{goal}%%**.',
          goal_calculation: :capacity,
          denominator_label: 'Average Capacity',
          calculation_description: 'The average number of persons occupying a bed each night divided by the system\'s total bed capacity for Transitional Housing during the reporting range.',
          calculation_column: :days_in_th_bed_in_period,
          detail_columns: [
            'days_in_th_bed_in_period',
          ],
        },
        rrh_average_bed_utilization: {
          category: 'Rare',
          sub_category: 'Capacity',
          column: :both,
          year_over_year_change: false,
          title: 'Average Bed Utilization in RRH',
          goal_description: 'The CoC will maintain Rapid Re-Housing utilization rates **higher than %{goal}%%**.',
          goal_calculation: :capacity,
          denominator_label: 'Average Capacity',
          calculation_description: 'The average number of persons occupying a bed each night divided by the system\'s total bed capacity for Rapid Re-Housing during the reporting range.',
          calculation_column: :days_in_rrh_bed_in_period,
          detail_columns: [
            'days_in_rrh_bed_in_period',
          ],
        },
        psh_average_bed_utilization: {
          category: 'Rare',
          sub_category: 'Capacity',
          column: :both,
          year_over_year_change: false,
          title: 'Average Bed Utilization in Permanent Supportive Housing',
          goal_description: 'The CoC will maintain Permanent Supportive Housing utilization rates **higher than %{goal}%%**.',
          goal_calculation: :capacity,
          denominator_label: 'Average Capacity',
          calculation_description: 'The average number of persons occupying a bed each night divided by the system\'s total bed capacity for Permanent Supportive Housing during the reporting range.',
          calculation_column: :days_in_psh_bed_in_period,
          detail_columns: [
            'days_in_psh_bed_in_period',
          ],
        },
        oph_average_bed_utilization: {
          category: 'Rare',
          sub_category: 'Capacity',
          column: :both,
          year_over_year_change: false,
          title: 'Average Bed Utilization in Other Permanent Housing',
          goal_description: 'The CoC will maintain Other Permanent Housing utilization rates **higher than %{goal}%%**.',
          goal_calculation: :capacity,
          denominator_label: 'Average Capacity',
          calculation_description: 'The average number of persons occupying a bed each night divided by the system\'s total bed capacity for Other Permanent Housing during the reporting range.',
          calculation_column: :days_in_oph_bed_in_period,
          detail_columns: [
            'days_in_oph_bed_in_period',
          ],
        },
        length_of_homeless_time_homeless_average: {
          category: 'Brief',
          sub_category: 'Time',
          column: :system,
          year_over_year_change: false,
          title: 'Length of Time Homeless (Average Days)',
          goal_description: 'Persons in the CoC will have an average combined length of time homeless in ES, SH, and TH of **no more than %{goal} days**.',
          goal_calculation: :time_time,
          denominator_label: '',
          calculation_description: 'The average number of days persons are homeless in ES, SH, and TH projects.',
          calculation_column: :days_homeless_es_sh_th,
          measure: 'Measure 1',
          detail_columns: [
            'days_homeless_es_sh_th',
          ],
        },
        length_of_homeless_time_homeless_median: {
          category: 'Brief',
          sub_category: 'Time',
          column: :system,
          year_over_year_change: false,
          title: 'Length of Time Homeless (Median Days)',
          goal_description: 'Persons in the CoC will have a median combined length of time homeless in ES, SH, and TH of **no more than %{goal} days**.',
          goal_calculation: :time_time,
          denominator_label: '',
          calculation_description: 'The median number of days persons are homeless in ES, SH, and TH projects',
          calculation_column: :days_homeless_es_sh_th,
          measure: 'Measure 1',
          detail_columns: [
            'days_homeless_es_sh_th',
          ],
        },
        length_of_homeless_stay_average: {
          category: 'Brief',
          sub_category: 'Time',
          column: :project,
          year_over_year_change: false,
          title: 'Length of Homeless Stay (Average Days)',
          goal_description: 'Persons in the CoC will have an average combined length of stay of **no more than %{goal} days** in a homeless project (SO, ES, SH, or TH).',
          goal_calculation: :time_stay,
          denominator_label: '',
          calculation_description: 'The average count of unique dates persons are homeless per enrollment.',
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
          year_over_year_change: false,
          title: 'Length of Homeless Stay (Median Days)',
          goal_description: 'Persons in the CoC will have a median combined length of stay of **no more than %{goal} days** in a homeless project (SO, ES, SH, or TH).',
          goal_calculation: :time_stay,
          denominator_label: '',
          calculation_description: 'The median count of unique dates persons are homeless per enrollment.',
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
          sub_category: 'Time',
          column: :system,
          year_over_year_change: false,
          title: 'Time Homeless Prior to PH Move-in (Average Days)',
          goal_description: 'Persons in the CoC will have an average combined length of time homeless in ES, SH, TH and PH prior to move-in of **no more than %{goal} days**.',
          goal_calculation: :time_move_in,
          denominator_label: '',
          calculation_description: 'The average number of days persons report being homeless prior to entering ES, SH, TH and PH projects, plus the time spent in those projects prior to Housing Move-In Date (as applicable).',
          calculation_column: :days_homeless_es_sh_th_ph,
          measure: 'Measure 1',
          detail_columns: [
            'days_homeless_es_sh_th_ph',
          ],
        },
        time_to_move_in_median: {
          category: 'Brief',
          sub_category: 'Time',
          column: :system,
          year_over_year_change: false,
          title: 'Time Homeless Prior to PH Move-in (Median Days)',
          goal_description: 'Persons in the CoC will have a median combined length of time homeless in ES, SH, TH and PH prior to move-in of **no more than %{goal} days**.',
          goal_calculation: :time_move_in,
          denominator_label: '',
          calculation_description: 'The median number of days persons report being homeless prior to entering ES, SH, TH and PH projects, plus the time spent in those projects prior to Housing Move-In Date (as applicable).',
          calculation_column: :days_homeless_es_sh_th_ph,
          measure: 'Measure 1',
          detail_columns: [
            'days_homeless_es_sh_th_ph',
          ],
        },
        retention_or_positive_destinations: {
          category: 'Non-Recurring',
          sub_category: 'Destination',
          column: :system,
          year_over_year_change: false,
          title: 'Number of People with a Successful Placement or Retention of Housing',
          goal_description: '**At least %{goal}%%** of persons will exit to a “positive” destination (as defined by HUD) or will retain housing.',
          goal_calculation: :destination,
          denominator_label: 'Total Exits',
          calculation_description: 'Data is from all successful exits in SPM Measure 7.',
          calculation_column: [:retention_or_positive_destination],
          detail_columns: [
            'retention_or_positive_destination',
          ],
        },
        so_positive_destinations: {
          category: 'Non-Recurring',
          sub_category: 'Destination',
          column: :both,
          year_over_year_change: false,
          title: 'Number of People Exiting SO to a Positive Destination',
          goal_description: '**At least %{goal}%%** of persons in SO will exit to a “positive” destination (as defined by HUD)',
          goal_calculation: :destination,
          denominator_label: 'Total Exits',
          calculation_description: 'The number of persons who exited SO to a positive destination divided by the total number of persons who exited SO.',
          calculation_column: :so_destination_positive,
          measure: 'Measure 7',
          detail_columns: [
            'so_destination',
          ],
        },
        es_sh_th_rrh_positive_destinations: {
          category: 'Non-Recurring',
          sub_category: 'Destination',
          column: :both,
          year_over_year_change: false,
          title: 'Number of People Exits from ES, SH, TH, RRH to a Positive Destination, or PH with No Move-in',
          goal_description: '**At least %{goal}%%** of persons housed in ES, SH, TH, and RRH projects will move into permanent housing at exit',
          goal_calculation: :destination,
          denominator_label: 'Total Exits',
          calculation_description: 'The number of persons who exited to permanent housing destination divided by the number of persons who exited ES, SH, TH, RRH, plus persons in other PH projects who exited without moving into housing.',
          calculation_column: :es_sh_th_rrh_destination_positive,
          measure: 'Measure 7',
          detail_columns: [
            'es_sh_th_rrh_destination',
          ],
        },
        moved_in_positive_destinations: {
          category: 'Non-Recurring',
          sub_category: 'Destination',
          column: :both,
          year_over_year_change: false,
          title: 'Number of People in RRH or PH with Move-in or Permanent Exit',
          goal_description: '**At least %{goal}%%** of persons remain housed in PH projects or exit to a permanent housing destination',
          goal_calculation: :destination,
          denominator_label: 'Total Exits/Move-ins',
          calculation_description: 'The number of persons with a Housing Move-In Date that either exited to a permanent destination after moving into housing or remained in the PH project divided by the number of persons housed by PH projects.',
          calculation_column: :moved_in_destination_positive,
          measure: 'Measure 7',
          detail_columns: [
            'moved_in_destination',
          ],
        },
        returned_in_six_months: {
          category: 'Non-Recurring',
          sub_category: 'Recidivism',
          column: :both,
          year_over_year_change: false,
          title: 'Number of People Who Returned to Homelessness Within Six Months',
          goal_description: 'The CoC will have **no more than %{goal}%%** of adults who exited to permanent destinations return to ES, SH, TH, or SO within six months of exit',
          goal_calculation: :recidivism_6_months,
          numerator_label: 'returned to homelessness',
          denominator_label: 'Total exits to permanent destinations',
          calculation_description: 'The number of persons who returned to homelessness within 6 months of exit divided by the number of persons who exited SO, ES, TH, SH, or PH to permanent destinations within two years prior to the report end date.',
          calculation_column: :returned_in_six_months,
          measure: 'Measure 2',
          detail_columns: [
            'days_to_return',
          ],
        },
        returned_in_two_years: {
          category: 'Non-Recurring',
          sub_category: 'Recidivism',
          column: :both,
          year_over_year_change: false,
          title: 'Number of People Who Returned to Homelessness Within Two Years',
          goal_description: 'The CoC will have **no more than %{goal}%%** of adults who exited to permanent destinations return to ES, SH, TH, or SO within two years of exit',
          goal_calculation: :recidivism_24_months,
          numerator_label: 'returned to homelessness',
          denominator_label: 'Total exits to permanent destinations',
          calculation_description: 'The number of persons who returned to homelessness within 2 years of exit divided by the number of persons who exited SO, ES, TH, SH, or PH to permanent destinations within two years prior to the report end date.',
          calculation_column: :returned_in_two_years,
          measure: 'Measure 2',
          detail_columns: [
            'days_to_return',
          ],
        },
        increased_income_all_clients: {
          category: 'Non-Recurring',
          sub_category: 'Income',
          column: :both,
          year_over_year_change: true,
          title: 'Number of Clients with Increased Income',
          goal_description: 'CoC-funded projects will increase the percentage of adults  who increase total income by **%{goal}%% annually**',
          goal_calculation: :income,
          denominator_label: 'Total Stayers',
          calculation_description: 'The number of adults in CoC-funded projects with an increased total income divided by the number of adults in CoC-funded projects.',
          calculation_column: [
            :increased_income__income_stayer,
            :increased_income__income_leaver,
          ],
          detail_columns: [
            'increased_income',
          ],
        },
        stayers_with_increased_income: {
          category: 'Non-Recurring',
          sub_category: 'Income',
          column: :both,
          year_over_year_change: true,
          title: 'Stayer with Increased Income',
          goal_description: 'CoC-funded projects will increase the percentage of adult stayers who increase total income by **%{goal}%% annually**',
          goal_calculation: :income,
          denominator_label: 'Total Stayers',
          calculation_description: 'The number of adult stayers in CoC-funded projects with an increased total income divided by the number of adult stayers in CoC-funded projects.',
          calculation_column: :increased_income__income_stayer,
          measure: 'Measure 4',
          detail_columns: [
            'income_stayer',
            'increased_income',
          ],
        },
        stayers_with_increased_earned_income: {
          category: 'Non-Recurring',
          sub_category: 'Income',
          column: :both,
          year_over_year_change: true,
          title: 'Stayer with Increased Earned Income',
          goal_description: 'CoC-funded projects will increase the percentage of adult stayers who increase total income by **%{goal}%% annually**',
          goal_calculation: :income,
          denominator_label: 'Total Stayers',
          calculation_description: 'The number of adult stayers in CoC-funded projects with an increased earned income divided by the number of adult stayers in CoC-funded projects.',
          calculation_column: :increased_earned_income__income_stayer,
          detail_columns: [
            'income_stayer',
            'earned_income_stayer',
          ],
        },
        stayers_with_increased_non_cash_income: {
          category: 'Non-Recurring',
          sub_category: 'Income',
          column: :both,
          year_over_year_change: true,
          title: 'Stayer with Increased Non-Employment Income',
          goal_description: 'CoC-funded projects will increase the percentage of adult stayers who increase total income by **%{goal}%% annually**',
          goal_calculation: :income,
          denominator_label: 'Total Stayers',
          calculation_description: 'The number of adult stayers in CoC-funded projects with an increased non-cash income divided by the number of adult stayers in CoC-funded projects.',
          calculation_column: :increased_non_cash_income__income_stayer,
          detail_columns: [
            'income_stayer',
            'non_employment_income_stayer',
          ],
        },
        leavers_with_increased_income: {
          category: 'Non-Recurring',
          sub_category: 'Income',
          column: :both,
          year_over_year_change: true,
          title: 'Leaver with Increased Income',
          goal_description: 'CoC-funded projects will increase the percentage of adult leavers who increase total income by **%{goal}%% annually**',
          goal_calculation: :income,
          denominator_label: 'Total Leavers',
          calculation_description: 'The number of adult leavers in CoC-funded projects with an increased total income divided by the number of adult leavers in CoC-funded projects.',
          calculation_column: :increased_income__income_leaver,
          measure: 'Measure 4',
          detail_columns: [
            'income_leaver',
            'increased_income',
          ],
        },
        leavers_with_increased_earned_income: {
          category: 'Non-Recurring',
          sub_category: 'Income',
          column: :both,
          year_over_year_change: true,
          title: 'Leaver with Increased Earned Income',
          goal_description: 'CoC-funded projects will increase the percentage of adult leavers who increase total income by **%{goal}%% annually**',
          goal_calculation: :income,
          denominator_label: 'Total Leavers',
          calculation_description: 'The number of adult leavers in CoC-funded projects with an increased earned income divided by the number of adult leavers in CoC-funded projects.',
          calculation_column: :increased_earned_income__income_leaver,
          detail_columns: [
            'income_leaver',
            'earned_income_leaver',
          ],
        },
        leavers_with_increased_non_cash_income: {
          category: 'Non-Recurring',
          sub_category: 'Income',
          column: :both,
          year_over_year_change: true,
          title: 'Leaver with Increased Non-Employment Income',
          goal_description: 'CoC-funded projects will increase the percentage of adult leavers who increase total income by **%{goal}%% annually**',
          goal_calculation: :income,
          denominator_label: 'Total Leavers',
          calculation_description: 'The number of adult leavers in CoC-funded projects with an increased non-cash income divided by the number of adult leavers in CoC-funded projects.',
          calculation_column: :increased_non_cash_income__income_leaver,
          detail_columns: [
            'income_leaver',
            'non_employment_income_leaver',
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
