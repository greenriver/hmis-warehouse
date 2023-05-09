###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Enrollment
  class UpdateR7Columns
    COLUMNS = [
      'UrgentReferral',
      'TimeToHousingLoss',
      'AnnualPercentAMI',
      'LiteralHomelessHistory',
      'ClientLeaseholder',
      'HOHLeaseholder',
      'SubsidyAtRisk',
      'EvictionHistory',
      'CriminalRecord',
      'IncarceratedAdult',
      'PrisonDischarge',
      'SexOffender',
      'DisabledHoH',
      'CurrentPregnant',
      'SingleParent',
      'DependentUnder6',
      'HH5Plus',
      'CoCPrioritized',
      'HPScreeningScore',
      'ThresholdScore',
    ].freeze

    # Pending HUD guidance, this preserves existing columns, and sets the new ones to nil
    # TargetScreenReqd is set if thee are any values in the columns
    def process(row)
      COLUMNS.each do |column|
        row[column] ||= nil
      end
      row['AnnualPercentAMI'] = annual_percent_ami(row)
      row['EvictionHistory'] = eviction_history(row)
      row['DependentUnder6'] = 2 if row['DependentUnder6']&.to_s == '1'
      row['TargetScreenReqd'] = screening_required?(row)

      row
    end

    def annual_percent_ami(row)
      return 0 if row['ZeroIncome']&.to_s == '1'
      return 2 if row['AnnualPercentAMI']&.to_s == '1'
      return 3 if row['AnnualPercentAMI']&.to_s == '2'

      row['AnnualPercentAMI']
    end

    def eviction_history(row)
      return 2 if row['EvictionHistory']&.to_s == '0' || row['EvictionHistory']&.to_s == '1'
      return 1 if row['EvictionHistory']&.to_s == '2'
      return 0 if row['EvictionHistory']&.to_s == '3'

      row['SubsidyAtRisk']
    end

    def screening_required?(row)
      values = row.slice(COLUMNS).values
      return nil if values.all?(nil)

      1
    end
  end
end
