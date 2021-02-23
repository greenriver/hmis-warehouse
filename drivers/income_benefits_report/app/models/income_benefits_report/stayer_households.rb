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
            description: 'Counts heads-of-household stayers who\'s most recent income assessment, regardless of DataCollectionStage, included income in the Earned category.  Percentage is out of heads-of-household stayers.',
          },
          'Households with Non-Employment Income at Last Update' => {
            count: count_stayers_hoh_with_unearned_income_at_last_update,
            percent: percent_stayers_hoh_with_unearned_income_at_last_update,
            description: 'Counts heads-of-household stayers who\'s most recent income assessment, regardless of DataCollectionStage, included IncomeFromAnySource but no income in the Earned category.  Percentage is out of heads-of-household stayers.',
          },
          'Households with Income from Any Source (Earned or Non-Employment) at Last Update' => {
            count: count_stayers_hoh_with_any_income_at_last_update,
            percent: percent_stayers_hoh_with_any_income_at_last_update,
            description: 'Counts heads-of-household stayers who\'s most recent income assessment, regardless of DataCollectionStage, included IncomeFromAnySource.  Percentage is out of heads-of-household stayers.',
          },
          'Total Adults with any income at Entry' => {
            count: count_stayers_adults_with_any_income_at_entry,
            percent: percent_stayers_adults_with_any_income_at_entry,
            description: 'Counts adult stayers who had income in the Earned category at DataCollectionStage 1 (Entry).  Percentage is out of adult stayers.',
          },
          'Average Adult Income at Entry' => {
            count: average_adult_stayer_income_value_at_entry,
            percent: nil,
            description: 'Sum of all TotalMonthlyIncome for adults with income at entry over the number of adults with income from any source at Entry.',
          },
          'Average Adult Income at Last Update' => {
            count: average_adult_stayer_income_value_at_last_update,
            percent: nil,
            description: 'Sum of all TotalMonthlyIncome for adults at their most-recent income assessment regardless of DataCollectionStage over the number of adults with income from any source.',
          },
          'Total Adults that Increased Income' => {
            count: count_adult_stayers_with_increased_income,
            percent: percent_adult_stayers_with_increased_income,
            description: 'Compares the TotalMonthlyIncome from the most-recent assessment with the earliest assessment taken within the enrollment in question.  Counts clients who\'s TotalMonthlyIncome has increased. Only includes clients where both assessments have a non-blank TotalMonthlyIncome.',
          },
          'Total Adults that Maintained Income' => {
            count: count_adult_stayers_with_maintained_income,
            percent: percent_adult_stayers_with_maintained_income,
            description: 'Compares the TotalMonthlyIncome from the most-recent assessment with the earliest assessment taken within the enrollment in question.  Counts clients who\'s TotalMonthlyIncome has not changed. Only includes clients where both assessments have a non-blank TotalMonthlyIncome.',
          },
          'Total Adults that Lost Income' => {
            count: count_adult_stayers_with_decreased_income,
            percent: percent_adult_stayers_with_decreased_income,
            description: 'Compares the TotalMonthlyIncome from the most-recent assessment with the earliest assessment taken within the enrollment in question.  Counts clients who\'s TotalMonthlyIncome has decreased. Only includes clients where both assessments have a non-blank TotalMonthlyIncome.',
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

    private def stayers_adults_with_any_income_at_entry
      filter_for_stayers(filter_for_adults(report_scope)).
        joins(enrollment: :income_benefits).
        merge(GrdaWarehouse::Hud::IncomeBenefit.with_any_income.at_entry)
    end

    private def count_stayers_adults_with_any_income_at_entry
      @count_stayers_adults_with_any_income_at_entry ||= stayers_adults_with_any_income_at_entry.select(:client_id).distinct.count
    end

    private def percent_stayers_adults_with_any_income_at_entry
      denominator = filter_for_stayers(filter_for_adults(report_scope)).select(:client_id).distinct.count
      return 0 unless denominator.positive?

      numerator = count_stayers_adults_with_any_income_at_entry
      return 0 unless numerator.positive?

      (numerator / denominator.to_f).round(2) * 100
    end

    private def total_adult_stayer_income_value_at_entry
      @total_adult_stayer_income_value_at_entry ||= stayers_adults_with_any_income_at_entry.sum(:TotalMonthlyIncome)
    end

    private def average_adult_stayer_income_value_at_entry
      denominator = count_stayers_adults_with_any_income_at_entry
      return 0 unless denominator.positive?

      numerator = total_adult_stayer_income_value_at_entry
      return 0 unless numerator.positive?

      numerator / denominator
    end

    private def stayers_adults_with_any_income_at_last_update
      stayers_most_recent_income_assessment.
        joins(enrollment: :income_benefits).
        merge(filter_for_stayers(filter_for_adults(report_scope))).
        merge(GrdaWarehouse::Hud::IncomeBenefit.with_any_income.at_last_update)
    end

    private def count_stayers_adults_with_any_income_at_last_update
      @count_stayers_adults_with_any_income_at_last_update ||= stayers_adults_with_any_income_at_last_update.select(:client_id).distinct.count
    end

    private def total_adult_stayer_income_value_at_last_update
      @total_adult_stayer_income_value_at_last_update ||= stayers_adults_with_any_income_at_last_update.sum(:TotalMonthlyIncome)
    end

    private def average_adult_stayer_income_value_at_last_update
      denominator = count_stayers_adults_with_any_income_at_last_update
      return 0 unless denominator.positive?

      numerator = total_adult_stayer_income_value_at_last_update
      return 0 unless numerator.positive?

      numerator / denominator
    end

    private def adult_stayers_with_two_income_assessments
      @adult_stayers_with_two_income_assessments ||= begin
        most_recent = stayers_adults_with_any_income_at_last_update.distinct.pluck(:client_id, :TotalMonthlyIncome).to_h
        earliest = stayers_adults_with_any_income_at_entry.distinct.pluck(:client_id, :TotalMonthlyIncome).to_h
        incomes = {}
        most_recent.each do |client_id, amount|
          next unless amount.present?

          previous_amount = earliest[client_id]
          next unless previous_amount.present?

          incomes[client_id] = { earliest: previous_amount, most_recent: amount }
        end
        incomes
      end
    end

    private def count_adult_stayers_with_two_income_assessments
      adult_stayers_with_two_income_assessments.count
    end

    private def adult_stayers_with_increased_income
      @adult_stayers_with_increased_income ||= begin
        Set.new.tap do |increased|
          adult_stayers_with_two_income_assessments.each do |client_id, amounts|
            increased << client_id if amounts[:most_recent] > amounts[:earliest]
          end
        end
      end
    end

    private def count_adult_stayers_with_increased_income
      adult_stayers_with_increased_income.count
    end

    private def percent_adult_stayers_with_increased_income
      numerator = count_adult_stayers_with_increased_income
      return 0 unless numerator.positive?

      denominator = count_adult_stayers_with_two_income_assessments
      return 0 unless denominator.positive?

      numerator / denominator
    end

    private def adult_stayers_with_decreased_income
      @adult_stayers_with_decreased_income ||= begin
        Set.new.tap do |decreased|
          adult_stayers_with_two_income_assessments.each do |client_id, amounts|
            decreased << client_id if amounts[:most_recent] < amounts[:earliest]
          end
        end
      end
    end

    private def count_adult_stayers_with_decreased_income
      adult_stayers_with_decreased_income.count
    end

    private def percent_adult_stayers_with_decreased_income
      numerator = count_adult_stayers_with_decreased_income
      return 0 unless numerator.positive?

      denominator = count_adult_stayers_with_two_income_assessments
      return 0 unless denominator.positive?

      numerator / denominator
    end

    private def adult_stayers_with_maintained_income
      @adult_stayers_with_maintained_income ||= begin
        Set.new.tap do |maintained|
          adult_stayers_with_two_income_assessments.each do |client_id, amounts|
            maintained << client_id if amounts[:most_recent] == amounts[:earliest]
          end
        end
      end
    end

    private def count_adult_stayers_with_maintained_income
      adult_stayers_with_maintained_income.count
    end

    private def percent_adult_stayers_with_maintained_income
      numerator = count_adult_stayers_with_maintained_income
      return 0 unless numerator.positive?

      denominator = count_adult_stayers_with_two_income_assessments
      return 0 unless denominator.positive?

      numerator / denominator
    end

    private def stayers_most_recent_income_assessment
      filter_for_stayers(report_scope).
        joins(enrollment: :income_benefits).
        includes(enrollment: :income_benefits).
        merge(
          GrdaWarehouse::Hud::IncomeBenefit.only_most_recent_by_enrollment.
          where(EnrollmentID: filter_for_stayers(report_scope).select(:enrollment_group_id)),
        )
    end

    private def stayers_earliest_income_assessment
      filter_for_stayers(report_scope).
        joins(enrollment: :income_benefits).
        includes(enrollment: :income_benefits).
        merge(
          GrdaWarehouse::Hud::IncomeBenefit.only_earliest_by_enrollment.
          where(EnrollmentID: filter_for_stayers(report_scope).select(:enrollment_group_id)),
        )
    end
  end
end
