###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement::Details
  extend ActiveSupport::Concern

  included do
    private def detail_hash
      @detail_hash ||= {
        count_of_homeless_clients: {
          category: 'Rare',
          title: 'Number of Homeless People',
          goal_description: 'The CoC will reduce total homelessness by X% annually (as reported during a single Point in Time)',
          calculation_description: 'The difference (as a percentage) between the total number of sheltered and unsheltered homeless reported in the most recent annual PIT Count and the total sheltered and unsheltered homeless reported in the previous year’s PIT Count',
        },
        count_of_sheltered_homeless_clients: {
          category: 'Rare',
          title: 'Number of Sheltered Homeless People',
          goal_description: 'The CoC will reduce total counts of sheltered homeless in HMIS by X% annually',
          calculation_description: 'The difference (as a percentage) between the number of un-duplicated total sheltered homeless persons reported in HMIS (via ES and TH projects) and the previous reporting period’s count',
        },
        count_of_unsheltered_homeless_clients: {
          category: 'Rare',
          title: 'Number of Sheltered Homeless People',
          goal_description: 'The CoC will reduce total counts of unsheltered homeless in HMIS by X% annually',
          calculation_description: 'The difference (as a percentage) between the number of un-duplicated total unsheltered homeless persons reported in HMIS (via SO projects) and the previous reporting period’s count',
        },
        first_time_homeless_clients: {
          category: 'Rare',
          title: 'Number of First-Time Homeless People',
          goal_description: '',
          calculation_description: '',
        },
        length_of_homeless_stay_average: {
          category: 'Brief',
          title: 'Length of Homeless Stay (Average Days)',
          goal_description: '',
          calculation_description: '',
        },
        length_of_homeless_stay_median: {
          category: 'Brief',
          title: 'Length of Homeless Stay (Median Days)',
          goal_description: '',
          calculation_description: '',
        },
        time_to_move_in_average: {
          category: 'Brief',
          title: 'Time to Move-in (Average Days)',
          goal_description: '',
          calculation_description: '',
        },
        time_to_move_in_median: {
          category: 'Brief',
          title: 'Time to Move-in (Median Days)',
          goal_description: '',
          calculation_description: '',
        },
        so_positive_destinations: {
          category: 'Non-Recurring',
          title: 'Number of People Exiting SO to a Positive Destination',
          goal_description: '',
          calculation_description: '',
        },
        es_sh_th_rrh_positive_destinations: {
          category: 'Non-Recurring',
          title: 'Number of People Exits from ES, SH, TH, RRH to a Positive Destination, or PH with No Move-in',
          goal_description: '',
          calculation_description: '',
        },
        moved_in_positive_destinations: {
          category: 'Non-Recurring',
          title: 'Number of People in RRH or PH with Move-in or Permanent Exit',
          goal_description: '',
          calculation_description: '',
        },
        returned_in_six_months: {
          category: 'Non-Recurring',
          title: 'Number of People Who Returned to Homelessness Within Six Months',
          goal_description: '',
          calculation_description: '',
        },
        returned_in_twenty_two_years: {
          category: 'Non-Recurring',
          title: 'Number of People Who Returned to Homelessness Within Two Years',
          goal_description: '',
          calculation_description: '',
        },
        stayers_with_increased_income: {
          category: 'Non-Recurring',
          title: 'Stayer With Increased Income',
          goal_description: '',
          calculation_description: '',
        },
        leavers_with_increased_income: {
          category: 'Non-Recurring',
          title: 'Leaver With Increased Income',
          goal_description: '',
          calculation_description: '',
        },
      }
    end

    def detail_title_for(key)
      detail_hash[key][:title]
    end

    def detail_category_for(key)
      detail_hash[key][:category]
    end
  end
end
