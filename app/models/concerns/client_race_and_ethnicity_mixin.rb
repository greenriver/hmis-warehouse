###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientRaceAndEthnicityMixin
  extend ActiveSupport::Concern
  included do
    scope :race_ethnicity_alternative, ->(key, hispanic_latinaeo = false) {
      scope = self
      columns = (HudUtility2024.race_fields - [:RaceNone]).map { |k| [k, 0] }.to_h

      key = key.to_sym
      if key.in?([:MultiRacial, :multi_racial])
        query = multi_racial_clients(include_hispanic_latinaeo: false)
        query = query.where(c_t[:HispanicLatinaeo].eq(hispanic_latinaeo ? 1 : 0))
        return scope.merge(query)
      elsif key.in?([:RaceNone, :race_none])
        return scope.where(c_t[:RaceNone].in([8, 9, 99]))
      else
        columns[key] = 1
        columns[:HispanicLatinaeo] = 1 if hispanic_latinaeo
        query = nil
        columns.each do |k, v|
          if query.nil?
            query = c_t[k].eq(v)
          else
            query = query.and(c_t[k].eq(v))
          end
        end
        scope.where(query)
      end
    }

    scope :multi_racial_clients, ->(include_hispanic_latinaeo: false) {
      # Looking at all races with responses of 1, where we have a sum > 1
      columns = [
        c_t[:AmIndAKNative],
        c_t[:Asian],
        c_t[:BlackAfAmerican],
        c_t[:NativeHIPacific],
        c_t[:White],
        c_t[:MidEastNAfrican],
      ]
      columns << c_t[:HispanicLatinaeo] if include_hispanic_latinaeo

      where(Arel.sql(columns.map(&:to_sql).join(' + ')).between(2..98))
    }
  end
end
