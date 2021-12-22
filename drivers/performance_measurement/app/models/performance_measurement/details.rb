###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement::Details
  extend ActiveSupport::Concern

  included do
    def summary_table
      detail_hash.group_by { |_, data| data[:category] }
    end

    def detail_title_for(key)
      detail_hash[key][:title]
    end

    def detail_category_for(key)
      detail_hash[key][:category]
    end

    def detail_goal_description_for(key)
      detail_hash[key][:goal_description]
    end

    def detail_calculation_description_for(key)
      detail_hash[key][:calculation_description]
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
      results.project.left_outer_joins(:hud_project).
        order(p_t[:ProjectName].asc, p_t[GrdaWarehouse::Hud::Project.project_type_column].asc).
        for_field(key).
        index_by(&:project_id)
    end
    memoize :project_details

    private def detail_hash
      @detail_hash ||= {
        count_of_homeless_clients: {
          category: 'Rare',
          column: :both,
          title: 'Number of Homeless People at PIT Count',
          goal_description: 'The CoC will reduce total homelessness by X% annually (as reported during a single Point in Time)',
          calculation_description: 'The difference (as a percentage) between the total number of sheltered and unsheltered homeless reported in the most recent annual PIT Count and the total sheltered and unsheltered homeless reported in the previous year’s PIT Count',
        },
        count_of_sheltered_homeless_clients: {
          category: 'Rare',
          column: :both,
          title: 'Number of Sheltered Homeless People',
          goal_description: 'The CoC will reduce total counts of sheltered homeless in HMIS by X% annually',
          calculation_description: 'The difference (as a percentage) between the number of un-duplicated total sheltered homeless persons reported in HMIS (via ES and TH projects) and the previous reporting period’s count',
        },
        count_of_unsheltered_homeless_clients: {
          category: 'Rare',
          column: :both,
          title: 'Number of Unsheltered Homeless People',
          goal_description: 'The CoC will reduce total counts of unsheltered homeless in HMIS by X% annually',
          calculation_description: 'The difference (as a percentage) between the number of un-duplicated total unsheltered homeless persons reported in HMIS (via SO projects) and the previous reporting period’s count',
        },
        first_time_homeless_clients: {
          category: 'Rare',
          column: :system,
          title: 'Number of First-Time Homeless People',
          goal_description: 'The CoC will reduce total counts of persons experiencing homelessness for the first time in HMIS by X% annually',
          calculation_description: 'The difference (as a percentage) between the number of persons who entered during the reporting period with no prior enrollments in  HMIS (via the CoC’s ES, SH, TH, and PH projects) and the previous reporting period’s count.',
        },
        length_of_homeless_stay_average: {
          category: 'Brief',
          column: :project,
          title: 'Length of Homeless Stay (Average Days)',
          goal_description: 'Persons in the CoC will have an average combined length of time homeless of no more than X days.',
          calculation_description: '1a. Average number of days persons are homeless in ES, SH, and TH projects.',
        },
        length_of_homeless_stay_median: {
          category: 'Brief',
          column: :project,
          title: 'Length of Homeless Stay (Median Days)',
          goal_description: 'Persons in the CoC will have a median combined length of time homeless of no more than X days.',
          calculation_description: '1a. Median number of days persons are homeless in ES, SH, and TH projects.',
        },
        time_to_move_in_average: {
          category: 'Brief',
          column: :both,
          title: 'Time to Move-in (Average Days)',
          goal_description: 'Persons in the CoC will have an average combined length of time homeless of no more than X days.',
          calculation_description: '1b. Average number of days persons report being homeless prior to entering ES, SH, TH and PH projects, plus the time spent in those projects prior to Housing Move-In Date (as appliable).',
        },
        time_to_move_in_median: {
          category: 'Brief',
          column: :both,
          title: 'Time to Move-in (Median Days)',
          goal_description: 'Persons in the CoC will have a median combined length of time homeless of no more than X days.',
          calculation_description: '1b. Median number of days persons report being homeless prior to entering ES, SH, TH and PH projects, plus the time spent in those projects prior to Housing Move-In Date (as appliable).',
        },
        so_positive_destinations: {
          category: 'Non-Recurring',
          column: :both,
          title: 'Number of People Exiting SO to a Positive Destination',
          goal_description: 'At least X% of persons in SO will exit to a “positive” destination (as defined by HUD)',
          calculation_description: 'Number of persons who exited street outreach to a positive destination / Number of persons who exited street outreach.',
        },
        es_sh_th_rrh_positive_destinations: {
          category: 'Non-Recurring',
          column: :both,
          title: 'Number of People Exits from ES, SH, TH, RRH to a Positive Destination, or PH with No Move-in',
          goal_description: 'At least X% of persons housed in ES, SH, TH, and RRH projects will move into permanent housing at exit',
          calculation_description: 'Number of persons who exited to permanent housing destination / Number of persons who exited ES, SH, TH, RRH, plus persons in other PH projects who exited without moving into housing',
        },
        moved_in_positive_destinations: {
          category: 'Non-Recurring',
          column: :both,
          title: 'Number of People in RRH or PH with Move-in or Permanent Exit',
          goal_description: 'At least X% of persons remain housed in PH projects or exit to a permanent housing destination',
          calculation_description: 'Number of persons with a Housing Move-In Date that either exited to a permanent destination after moving into housing or remained in the PH project / Number of persons housed by PH projects',
        },
        returned_in_six_months: {
          category: 'Non-Recurring',
          column: :both,
          title: 'Number of People Who Returned to Homelessness Within Six Months',
          goal_description: 'The CoC will have no more than X% of adults who exited to permanent housing return to ES, SH, TH, or SO within six months of exit',
          calculation_description: 'Based on clients who exited SO, ES, TH, SH, or PH to a permanent housing destination in the date range two years prior to the report date range: Number of persons who returned to SO, ES, TH, SH or PH within 6 months of exit / Number of persons who exited SO, ES, TH, SH, or PH to a permanent housing destination in the date range two years prior to the report date range',
        },
        returned_in_two_years: {
          category: 'Non-Recurring',
          column: :both,
          title: 'Number of People Who Returned to Homelessness Within Two Years',
          goal_description: 'The CoC will have no more than X% of adults who exited to permanent housing return to ES, SH, TH, or Outreach within two years of exit',
          calculation_description: 'Based on clients who exited SO, ES, TH, SH, or PH to a permanent housing destination in the date range two years prior to the report date range: Number of persons who returned to SO, ES, TH, SH or PH within 2 years of exit / Number of persons who exited SO, ES, TH, SH, or PH to a permanent housing destination in the date range two years prior to the report date range',
        },
        stayers_with_increased_income: {
          category: 'Non-Recurring',
          column: :both,
          title: 'Stayer With Increased Income',
          goal_description: 'CoC-funded projects will increase the percentage of adult leavers who increase total income by X% annually',
          calculation_description: 'Number of adult stayers in CoC-funded projects with increased total income / Number of adult system stayers in CoC-funded projects',
        },
        leavers_with_increased_income: {
          category: 'Non-Recurring',
          column: :both,
          title: 'Leaver With Increased Income',
          goal_description: 'CoC-funded projects will increase the percentage of adult stayers who increase total income by X% annually',
          calculation_description: 'Number of adult leavers from CoC-funded projects with increased total income / Number of adult system leavers from CoC-funded projects',
        },
      }
    end
  end
end
