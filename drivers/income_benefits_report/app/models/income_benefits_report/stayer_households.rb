###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  IncomeBenefitsReport::StayerHouseholds
  extend ActiveSupport::Concern
  included do
    def stayer_households_data
      {
        stayers_hoh_with_earned_income_at_last_update: {
          title: 'Households with Earned Income at Last Update',
          count: count_stayers_hoh_with_earned_income_at_last_update,
          denominator: stayers_hoh_count,
          percent: percent_stayers_hoh_with_earned_income_at_last_update,
          description: 'Counts heads-of-household stayers whose most recent income assessment, regardless of DataCollectionStage, included income in the Earned category.  Percentage is out of heads-of-household stayers.',
          scope: stayers_hoh_with_earned_income_at_last_update,
          income_relation: :later_income_record,
        },
        stayers_hoh_with_unearned_income_at_last_update: {
          title: 'Households with Non-Employment Income at Last Update',
          count: count_stayers_hoh_with_unearned_income_at_last_update,
          denominator: stayers_hoh_count,
          percent: percent_stayers_hoh_with_unearned_income_at_last_update,
          description: 'Counts heads-of-household stayers whose most recent income assessment, regardless of DataCollectionStage, included IncomeFromAnySource but no income in the Earned category.  Percentage is out of heads-of-household stayers.',
          scope: stayers_hoh_with_unearned_income_at_last_update,
          income_relation: :later_income_record,
        },
        stayers_hoh_with_any_income_at_last_update: {
          title: 'Households with Income from Any Source (Earned or Non-Employment) at Last Update',
          count: count_stayers_hoh_with_any_income_at_last_update,
          denominator: stayers_hoh_count,
          percent: percent_stayers_hoh_with_any_income_at_last_update,
          description: 'Counts heads-of-household stayers whose most recent income assessment, regardless of DataCollectionStage, included IncomeFromAnySource.  Percentage is out of heads-of-household stayers.',
          scope: stayers_hoh_with_any_income_at_last_update,
          income_relation: :later_income_record,
        },
        stayers_adults_with_any_income_at_entry: {
          title: 'Total Adults with any Income at Entry',
          count: count_stayers_adults_with_any_income_at_entry,
          denominator: stayers_adults_count,
          percent: percent_stayers_adults_with_any_income_at_entry,
          description: 'Counts adult stayers who had income in the Earned category at DataCollectionStage 1 (Entry).  Percentage is out of adult stayers.',
          scope: stayers_adults_with_any_income_at_entry,
          income_relation: :earlier_income_record,
        },
        adult_stayers_with_entry_income: {
          title: 'Average Adult Income at Entry',
          count: average_adult_stayer_income_value_at_entry,
          percent: nil,
          description: 'Sum of all TotalMonthlyIncome for adults with income at entry over the number of adults with income from any source at Entry.',
          scope: stayers_adults_with_any_income_at_entry,
          income_relation: :earlier_income_record,
        },
        stayers_adults_with_any_income_at_last_update: {
          title: 'Average Adult Income at Last Update',
          count: average_adult_stayer_income_value_at_last_update,
          percent: nil,
          description: 'Sum of all TotalMonthlyIncome for adults at their most-recent income assessment regardless of DataCollectionStage over the number of adults with income from any source.',
          scope: stayers_adults_with_any_income_at_last_update,
          income_relation: :later_income_record,
        },
        adult_stayers_with_increased_income_records: {
          title: 'Total Adults that Increased Income',
          count: count_adult_stayers_with_increased_income,
          denominator: count_adult_stayers_with_two_income_assessments,
          percent: percent_adult_stayers_with_increased_income,
          description: 'Compares the TotalMonthlyIncome from the most-recent assessment with the earliest assessment taken within the enrollment in question.  Counts clients whose TotalMonthlyIncome has increased. Only includes clients where both assessments have a non-blank TotalMonthlyIncome.',
          scope: adult_stayers_with_increased_income_records,
          income_relation: :later_income_record,
        },
        adult_stayers_with_maintained_income_records: {
          title: 'Total Adults that Maintained Income',
          count: count_adult_stayers_with_maintained_income,
          denominator: count_adult_stayers_with_two_income_assessments,
          percent: percent_adult_stayers_with_maintained_income,
          description: 'Compares the TotalMonthlyIncome from the most-recent assessment with the earliest assessment taken within the enrollment in question.  Counts clients whose TotalMonthlyIncome has not changed. Only includes clients where both assessments have a non-blank TotalMonthlyIncome.',
          scope: adult_stayers_with_maintained_income_records,
          income_relation: :later_income_record,
        },
        adult_stayers_with_decreased_income_records: {
          title: 'Total Adults that Lost Income',
          count: count_adult_stayers_with_decreased_income,
          denominator: count_adult_stayers_with_two_income_assessments,
          percent: percent_adult_stayers_with_decreased_income,
          description: 'Compares the TotalMonthlyIncome from the most-recent assessment with the earliest assessment taken within the enrollment in question.  Counts clients whose TotalMonthlyIncome has decreased. Only includes clients where both assessments have a non-blank TotalMonthlyIncome.',
          scope: adult_stayers_with_decreased_income_records,
          income_relation: :later_income_record,
        },
      }
    end

    # Earned
    private def percent_stayers_hoh_with_earned_income_at_last_update
      calc_percent(count_stayers_hoh_with_earned_income_at_last_update, stayers_hoh_count)
    end

    private def count_stayers_hoh_with_earned_income_at_last_update
      @count_stayers_hoh_with_earned_income_at_last_update ||= stayers_hoh_with_earned_income_at_last_update.
        count
    end

    private def stayers_hoh_with_earned_income_at_last_update
      stayers_scope.heads_of_household.
        joins(:later_income_record).
        merge(IncomeBenefitsReport::Income.with_earned_income.later.date_range(report_date_range))
    end
    # End Earned

    # Any Income
    private def percent_stayers_hoh_with_any_income_at_last_update
      calc_percent(count_stayers_hoh_with_any_income_at_last_update, stayers_hoh_count)
    end

    private def count_stayers_hoh_with_any_income_at_last_update
      @count_stayers_hoh_with_any_income_at_last_update ||= stayers_hoh_with_any_income_at_last_update.
        count
    end

    private def stayers_hoh_with_any_income_at_last_update
      stayers_scope.heads_of_household.
        joins(:later_income_record).
        merge(IncomeBenefitsReport::Income.with_any_income.later.date_range(report_date_range))
    end
    # End Any Income

    # Unearned
    private def percent_stayers_hoh_with_unearned_income_at_last_update
      calc_percent(count_stayers_hoh_with_unearned_income_at_last_update, stayers_hoh_count)
    end

    private def count_stayers_hoh_with_unearned_income_at_last_update
      @count_stayers_hoh_with_unearned_income_at_last_update ||= stayers_hoh_with_unearned_income_at_last_update.
        count
    end

    private def stayers_hoh_with_unearned_income_at_last_update
      stayers_scope.heads_of_household.
        joins(:later_income_record).
        merge(IncomeBenefitsReport::Income.with_unearned_income.later.date_range(report_date_range))
    end
    # End Unearned

    private def stayers_adults_with_any_income_at_entry
      stayers_adults.joins(:earlier_income_record).
        merge(IncomeBenefitsReport::Income.with_any_income.earlier.date_range(report_date_range))
    end

    private def count_stayers_adults_with_any_income_at_entry
      @count_stayers_adults_with_any_income_at_entry ||= stayers_adults_with_any_income_at_entry.count
    end

    private def percent_stayers_adults_with_any_income_at_entry
      calc_percent(count_stayers_adults_with_any_income_at_entry, stayers_adults_count)
    end

    private def total_adult_stayer_income_value_at_entry
      @total_adult_stayer_income_value_at_entry ||= adult_stayers_with_entry_income.
        sum(r_income_t[:TotalMonthlyIncome])
    end

    private def adult_stayers_with_entry_income
      stayers_adults.joins(:earlier_income_record).
        merge(IncomeBenefitsReport::Income.earlier.date_range(report_date_range))
    end

    private def average_adult_stayer_income_value_at_entry
      denominator = count_stayers_adults_with_any_income_at_entry
      return 0 unless denominator.positive?

      numerator = total_adult_stayer_income_value_at_entry
      return 0 unless numerator.positive?

      (numerator / denominator).round
    end

    private def stayers_adults_with_any_income_at_last_update
      stayers_adults.joins(:later_income_record).
        merge(IncomeBenefitsReport::Income.with_any_income.later.date_range(report_date_range))
    end

    private def count_stayers_adults_with_any_income_at_last_update
      @count_stayers_adults_with_any_income_at_last_update ||= stayers_adults_with_any_income_at_last_update.count
    end

    private def total_adult_stayer_income_value_at_last_update
      @total_adult_stayer_income_value_at_last_update ||= stayers_adults_with_any_income_at_last_update.
        merge(IncomeBenefitsReport::Income.later.date_range(report_date_range)).
        sum(r_income_t[:TotalMonthlyIncome])
    end

    private def average_adult_stayer_income_value_at_last_update
      denominator = count_stayers_adults_with_any_income_at_last_update
      return 0 unless denominator.positive?

      numerator = total_adult_stayer_income_value_at_last_update
      return 0 unless numerator.positive?

      (numerator / denominator).round
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

    private def adult_stayers_with_increased_income_records
      stayers_adults.where(client_id: adult_stayers_with_increased_income)
    end

    private def count_adult_stayers_with_increased_income
      adult_stayers_with_increased_income.count
    end

    private def percent_adult_stayers_with_increased_income
      calc_percent(count_adult_stayers_with_increased_income, count_adult_stayers_with_two_income_assessments)
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

    private def adult_stayers_with_decreased_income_records
      stayers_adults.where(client_id: adult_stayers_with_decreased_income)
    end

    private def count_adult_stayers_with_decreased_income
      adult_stayers_with_decreased_income.count
    end

    private def percent_adult_stayers_with_decreased_income
      calc_percent(count_adult_stayers_with_decreased_income, count_adult_stayers_with_two_income_assessments)
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

    private def adult_stayers_with_maintained_income_records
      stayers_adults.where(client_id: adult_stayers_with_maintained_income)
    end

    private def count_adult_stayers_with_maintained_income
      adult_stayers_with_maintained_income.count
    end

    private def percent_adult_stayers_with_maintained_income
      calc_percent(count_adult_stayers_with_maintained_income, count_adult_stayers_with_two_income_assessments)
    end
  end
end
