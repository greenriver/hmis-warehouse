###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  IncomeBenefitsReport::LeaverHouseholds
  extend ActiveSupport::Concern
  included do
    def leaver_households_data
      {
        'Households with Earned Income at Last Update' => {
          count: count_leavers_hoh_with_earned_income_at_last_update,
          percent: percent_leavers_hoh_with_earned_income_at_last_update,
          description: 'Counts heads-of-household leavers who\'s most recent income assessment, regardless of DataCollectionStage, included income in the Earned category.  Percentage is out of heads-of-household leavers.',
        },
        'Households with Non-Employment Income at Last Update' => {
          count: count_leavers_hoh_with_unearned_income_at_last_update,
          percent: percent_leavers_hoh_with_unearned_income_at_last_update,
          description: 'Counts heads-of-household leavers who\'s most recent income assessment, regardless of DataCollectionStage, included IncomeFromAnySource but no income in the Earned category.  Percentage is out of heads-of-household leavers.',
        },
        'Households with Income from Any Source (Earned or Non-Employment) at Last Update' => {
          count: count_leavers_hoh_with_any_income_at_last_update,
          percent: percent_leavers_hoh_with_any_income_at_last_update,
          description: 'Counts heads-of-household leavers who\'s most recent income assessment, regardless of DataCollectionStage, included IncomeFromAnySource.  Percentage is out of heads-of-household leavers.',
        },
        'Total Adults with any income at Entry' => {
          count: count_leavers_adults_with_any_income_at_entry,
          percent: percent_leavers_adults_with_any_income_at_entry,
          description: 'Counts adult leavers who had income in the Earned category at DataCollectionStage 1 (Entry).  Percentage is out of adult leavers.',
        },
        'Average Adult Income at Entry' => {
          count: average_adult_leaver_income_value_at_entry,
          percent: nil,
          description: 'Sum of all TotalMonthlyIncome for adults with income at entry over the number of adults with income from any source at Entry.',
        },
        'Average Adult Income at Last Update' => {
          count: average_adult_leaver_income_value_at_last_update,
          percent: nil,
          description: 'Sum of all TotalMonthlyIncome for adults at their most-recent income assessment regardless of DataCollectionStage over the number of adults with income from any source.',
        },
        'Total Adults that Increased Income' => {
          count: count_adult_leavers_with_increased_income,
          percent: percent_adult_leavers_with_increased_income,
          description: 'Compares the TotalMonthlyIncome from the most-recent assessment with the earliest assessment taken within the enrollment in question.  Counts clients who\'s TotalMonthlyIncome has increased. Only includes clients where both assessments have a non-blank TotalMonthlyIncome.',
        },
        'Total Adults that Maintained Income' => {
          count: count_adult_leavers_with_maintained_income,
          percent: percent_adult_leavers_with_maintained_income,
          description: 'Compares the TotalMonthlyIncome from the most-recent assessment with the earliest assessment taken within the enrollment in question.  Counts clients who\'s TotalMonthlyIncome has not changed. Only includes clients where both assessments have a non-blank TotalMonthlyIncome.',
        },
        'Total Adults that Lost Income' => {
          count: count_adult_leavers_with_decreased_income,
          percent: percent_adult_leavers_with_decreased_income,
          description: 'Compares the TotalMonthlyIncome from the most-recent assessment with the earliest assessment taken within the enrollment in question.  Counts clients who\'s TotalMonthlyIncome has decreased. Only includes clients where both assessments have a non-blank TotalMonthlyIncome.',
        },
      }
    end

    # Earned
    private def percent_leavers_hoh_with_earned_income_at_last_update
      calc_percent(count_leavers_hoh_with_earned_income_at_last_update, leavers_hoh_count)
    end

    private def count_leavers_hoh_with_earned_income_at_last_update
      @count_leavers_hoh_with_earned_income_at_last_update ||= leavers_scope.heads_of_household.
        joins(:later_income_record).
        merge(IncomeBenefitsReport::Income.with_earned_income).
        count
    end
    # End Earned

    # Any Income
    private def percent_leavers_hoh_with_any_income_at_last_update
      calc_percent(count_leavers_hoh_with_any_income_at_last_update, leavers_hoh_count)
    end

    private def count_leavers_hoh_with_any_income_at_last_update
      @count_leavers_hoh_with_any_income_at_last_update ||= leavers_scope.heads_of_household.
        joins(:later_income_record).
        merge(IncomeBenefitsReport::Income.with_any_income).
        count
    end
    # End Any Income

    # Unearned
    private def percent_leavers_hoh_with_unearned_income_at_last_update
      calc_percent(count_leavers_hoh_with_unearned_income_at_last_update, leavers_hoh_count)
    end

    private def count_leavers_hoh_with_unearned_income_at_last_update
      @count_leavers_hoh_with_unearned_income_at_last_update ||= leavers_scope.heads_of_household.
        joins(:later_income_record).
        merge(IncomeBenefitsReport::Income.with_unearned_income).
        count
    end
    # End Unearned

    private def leavers_adults_with_any_income_at_entry
      leavers_adults.joins(:earlier_income_record).
        merge(IncomeBenefitsReport::Income.with_any_income)
    end

    private def count_leavers_adults_with_any_income_at_entry
      @count_leavers_adults_with_any_income_at_entry ||= leavers_adults_with_any_income_at_entry.count
    end

    private def percent_leavers_adults_with_any_income_at_entry
      calc_percent(count_leavers_adults_with_any_income_at_entry, leavers_adults_count)
    end

    private def total_adult_leaver_income_value_at_entry
      income_t = IncomeBenefitsReport::Income.arel_table
      @total_adult_leaver_income_value_at_entry ||= leavers_adults.joins(:earlier_income_record).sum(income_t[:TotalMonthlyIncome])
    end

    private def average_adult_leaver_income_value_at_entry
      calc_percent(total_adult_leaver_income_value_at_entry, count_leavers_adults_with_any_income_at_entry)
    end

    private def leavers_adults_with_any_income_at_last_update
      leavers_adults.joins(:later_income_record).
        merge(IncomeBenefitsReport::Income.with_any_income)
    end

    private def count_leavers_adults_with_any_income_at_last_update
      @count_leavers_adults_with_any_income_at_last_update ||= leavers_adults_with_any_income_at_last_update.count
    end

    private def total_adult_leaver_income_value_at_last_update
      income_t = IncomeBenefitsReport::Income.arel_table
      @total_adult_leaver_income_value_at_last_update ||= leavers_adults_with_any_income_at_last_update.sum(income_t[:TotalMonthlyIncome])
    end

    private def average_adult_leaver_income_value_at_last_update
      calc_percent(total_adult_leaver_income_value_at_last_update, count_leavers_adults_with_any_income_at_last_update)
    end

    private def adult_leavers_with_two_income_assessments
      @adult_leavers_with_two_income_assessments ||= begin
        most_recent = leavers_adults_with_any_income_at_last_update.distinct.pluck(:client_id, :TotalMonthlyIncome).to_h
        earliest = leavers_adults_with_any_income_at_entry.distinct.pluck(:client_id, :TotalMonthlyIncome).to_h
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

    private def count_adult_leavers_with_two_income_assessments
      adult_leavers_with_two_income_assessments.count
    end

    private def adult_leavers_with_increased_income
      @adult_leavers_with_increased_income ||= begin
        Set.new.tap do |increased|
          adult_leavers_with_two_income_assessments.each do |client_id, amounts|
            increased << client_id if amounts[:most_recent] > amounts[:earliest]
          end
        end
      end
    end

    private def count_adult_leavers_with_increased_income
      adult_leavers_with_increased_income.count
    end

    private def percent_adult_leavers_with_increased_income
      calc_percent(count_adult_leavers_with_increased_income, count_adult_leavers_with_two_income_assessments)
    end

    private def adult_leavers_with_decreased_income
      @adult_leavers_with_decreased_income ||= begin
        Set.new.tap do |decreased|
          adult_leavers_with_two_income_assessments.each do |client_id, amounts|
            decreased << client_id if amounts[:most_recent] < amounts[:earliest]
          end
        end
      end
    end

    private def count_adult_leavers_with_decreased_income
      adult_leavers_with_decreased_income.count
    end

    private def percent_adult_leavers_with_decreased_income
      calc_percent(count_adult_leavers_with_decreased_income, count_adult_leavers_with_two_income_assessments)
    end

    private def adult_leavers_with_maintained_income
      @adult_leavers_with_maintained_income ||= begin
        Set.new.tap do |maintained|
          adult_leavers_with_two_income_assessments.each do |client_id, amounts|
            maintained << client_id if amounts[:most_recent] == amounts[:earliest]
          end
        end
      end
    end

    private def count_adult_leavers_with_maintained_income
      adult_leavers_with_maintained_income.count
    end

    private def percent_adult_leavers_with_maintained_income
      calc_percent(count_adult_leavers_with_maintained_income, count_adult_leavers_with_two_income_assessments)
    end
  end
end
