###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::RaceAndEthnicity
  extend ActiveSupport::Concern

  private def race_and_ethnicity_buckets
    (HudUtility2024.races.keys + ['Multiple']).map do |r|
      (HudUtility2024.ethnicities.keys - [:unknown]).map do |e|
        next if r == 'HispanicLatinaeo' && e == :non_hispanic_latinaeo
        next if r == 'RaceNone' && e != :unknown

        {
          race: r,
          ethnicity: e,
        }
      end
    end.flatten(1).compact
  end

  def race_and_ethnicity_title(key)
    race = if key[:race] == 'Multiple'
      'Multi-Racial'
    else
      HudUtility2024.race(key[:race])
    end
    "#{race} - #{HudUtility2024.ethnicity(key[:ethnicity])}"
  end

  def race_and_ethnicity_bucket_titles
    race_and_ethnicity_buckets.map do |key|
      [
        key,
        race_and_ethnicity_title(key),
      ]
    end.to_h
  end

  def race_and_ethnicity_bucket_titles_for_details
    race_and_ethnicity_bucket_titles.invert.transform_values { |v| [v[:race], v[:ethnicity]].join('-') }
  end

  def race_and_ethnicity_bucket(client_races)
    races = []
    races << 'AmIndAKNative' if client_races[:AmIndAKNative] == 1
    races << 'Asian' if client_races[:Asian] == 1
    races << 'BlackAfAmerican' if client_races[:BlackAfAmerican] == 1
    races << 'NativeHIPacific' if client_races[:NativeHIPacific] == 1
    races << 'White' if client_races[:White] == 1
    races << 'HispanicLatinaeo' if client_races[:HispanicLatinaeo] == 1
    races << 'MidEastNAfrican' if client_races[:MidEastNAfrican] == 1
    race = 'RaceNone' if client_races[:RaceNone].in?([8, 9, 99]) || races.empty?

    races_without_hispanic = races - ['HispanicLatinaeo']
    # Identify as multiple races excluding HispanicLatinaeo
    race ||= 'Multiple' if races_without_hispanic.count > 1

    # Identify as only one race (even if HispanicLatinaeo), return the one other race
    race ||= races_without_hispanic.first if races_without_hispanic.count == 1
    race ||= races.first

    # mirror Client.race_hispanic_latinaeo
    ethnicity = :hispanic_latinaeo if client_races[:HispanicLatinaeo] == 1
    # mirror Client.race_not_hispanic_latinaeo
    ethnicity ||= :non_hispanic_latinaeo if client_races[:HispanicLatinaeo] == 0 && client_races[:RaceNone].nil?

    ethnicity ||= :unknown

    {
      race: race,
      ethnicity: ethnicity,
    }
  end
end
