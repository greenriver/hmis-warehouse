###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
#

module HudTwentyTwentyToTwentyTwentyTwo::Enrollment
  class UpdateR7Columns
    COLUMNS = [
      'UrgentReferral',
      'TimeToHousingLoss',
      'AnnualPercentAMI',
      'LiteralHomelessHistory',
      'ClientLeaseholder',
      'HOHLeasesholder',
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
        row[column] = nil unless row.keys.include?(column)
      end
      row['TargetScreenReqd'] = screening_required?(row)

      row
    end

    def screening_required?(row)
      values = row.slice(COLUMNS).values
      return nil if values.all?(nil)

      1
    end
  end
end
