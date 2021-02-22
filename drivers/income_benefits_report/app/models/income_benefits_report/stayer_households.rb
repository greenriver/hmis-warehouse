###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  IncomeBenefitsReport::StayerHouseholds
  extend ActiveSupport::Concern
  included do
    def stayer_households_data
      @stayer_households_data ||= Rails.cache.fetch(cache_key_for_section('stayer_households'), expires_in: expiration_length) do
        {
          'Households with Earned Income at Last Update' => {
            count: count_stayers_hoh_with_earned_income_at_last_update,
            percent: percent_stayers_hoh_with_earned_income_at_last_update,
            # description: 'Describe calculation here',
          },
          'Households with Non-Employment Income at Last Update' => {
            count: count_stayers_hoh_with_unearned_income_at_last_update,
            percent: percent_stayers_hoh_with_unearned_income_at_last_update,
          },
          'Households with Income from Any Source (Earned or Non-Employment) at Last Update' => {
            count: count_stayers_hoh_with_any_income_at_last_update,
            percent: percent_stayers_hoh_with_any_income_at_last_update,
          },
          'Total Adults with Entries' => {
            count: 0,
            percent: 0,
          },
          'Total Adults with Exits' => {
            count: 0,
            percent: 0,
          },
          'Average Income at Entry' => {
            count: 0,
            percent: 0,
          },
          'Average Income at Last Update' => {
            count: 0,
            percent: 0,
          },
          'Total Adults that Increased Income' => {
            count: 0,
            percent: 0,
          },
          'Total Adults that Maintained Income' => {
            count: 0,
            percent: 0,
          },
          'Total Adults that Lost Income' => {
            count: 0,
            percent: 0,
          },
        }
      end
    end

    # Earned
    private def percent_stayers_hoh_with_earned_income_at_last_update
      denominator = stayers_hoh.select(:client_id).count
      return 0 unless denominator.positive?

      numerator = count_stayers_hoh_with_earned_income_at_last_update
      return 0 unless numerator.positive?

      (numerator / denominator.to_f).round(2) * 100
    end

    private def count_stayers_hoh_with_earned_income_at_last_update
      @count_stayers_hoh_with_earned_income_at_last_update ||= stayers_hoh_with_earned_income_at_last_update.select(:client_id).count
    end

    private def stayers_hoh_with_earned_income_at_last_update
      stayers_most_recent_income_assessment.merge(hoh_scope).merge(GrdaWarehouse::Hud::IncomeBenefit.with_earned_income)
    end

    # End Earned

    # Any Income
    private def percent_stayers_hoh_with_any_income_at_last_update
      denominator = stayers_hoh.select(:client_id).count
      return 0 unless denominator.positive?

      numerator = count_stayers_hoh_with_any_income_at_last_update
      return 0 unless numerator.positive?

      (numerator / denominator.to_f).round(2) * 100
    end

    private def count_stayers_hoh_with_any_income_at_last_update
      @count_stayers_hoh_with_any_income_at_last_update ||= stayers_hoh_with_any_income_at_last_update.select(:client_id).count
    end

    private def stayers_hoh_with_any_income_at_last_update
      stayers_most_recent_income_assessment.merge(hoh_scope).merge(GrdaWarehouse::Hud::IncomeBenefit.with_any_income)
    end
    # End Any Income

    # Unearned
    private def percent_stayers_hoh_with_unearned_income_at_last_update
      denominator = stayers_hoh.select(:client_id).count
      return 0 unless denominator.positive?

      numerator = count_stayers_hoh_with_unearned_income_at_last_update
      return 0 unless numerator.positive?

      (numerator / denominator.to_f).round(2) * 100
    end

    private def count_stayers_hoh_with_unearned_income_at_last_update
      @count_stayers_hoh_with_unearned_income_at_last_update ||= stayers_hoh_with_unearned_income_at_last_update.select(:client_id).count
    end

    private def stayers_hoh_with_unearned_income_at_last_update
      stayers_most_recent_income_assessment.merge(hoh_scope).merge(GrdaWarehouse::Hud::IncomeBenefit.with_unearned_income)
    end
    # End Unearned

    private def stayers_most_recent_income_assessment
      filter_for_stayers(report_scope).
        joins(enrollment: :income_benefits).
        includes(enrollment: :income_benefits).
        merge(
          GrdaWarehouse::Hud::IncomeBenefit.only_most_recent_by_enrollment.
          where(EnrollmentID: filter_for_stayers(report_scope).select(:enrollment_group_id)),
        )
    end

    # stayers_hoh_count

    # private def stayers_hoh_count
    #   filter_for_stayers(hoh_scope).select(:client_id).distinct.count
    # end

    # private def stayers_adult_count
    #   filter_for_stayers(filter_for_adults(hoh_scope)).select(:client_id).distinct.count
    # end

    # private def stayers_child_count
    #   filter_for_stayers(filter_for_children(hoh_scope)).select(:client_id).distinct.count
    # end

    # private def leavers_hoh_count
    #   filter_for_leavers(hoh_scope).select(:client_id).distinct.count
    # end

    # private def leavers_adult_count
    #   filter_for_leavers(filter_for_adults(hoh_scope)).select(:client_id).distinct.count
    # end

    # private def leavers_child_count
    #   filter_for_leavers(filter_for_children(hoh_scope)).select(:client_id).distinct.count
    # end
  end
end
