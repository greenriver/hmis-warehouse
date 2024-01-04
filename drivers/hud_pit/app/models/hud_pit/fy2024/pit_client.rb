###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# This is a wrapper around PIT Clients to associate version-specific logic with a name space,
# it does not use STI as there is no per-instance behavior associated with these models
module HudPit::Fy2024
  class PitClient < HudPit::Fy2022::PitClient
    def self.pit_race(client)
      # HUD specified a different vocabulary for PIT races that allows Hispanic/Latina/e/o to be both a single race,
      # and be combined with another race response without triggering the multi-racial label
      if multi_racial?(client)
        if hispanic_latinaeo?(client)
          'Multi-Racial & Hispanic/Latina/e/o'
        else
          'Multi-Racial (not Hispanic/Latina/e/o)'
        end
      elsif other_than_hispanic_latinaeo?(client)
        race = ::HudUtility2024.race(race_fields(client).first)
        race += ' & Hispanic/Latina/e/o' if hispanic_latinaeo?(client)
        race
      else
        'Hispanic/Latina/e/o'
      end
    end

    def self.more_than_one_gender(client)
      @gender_fields ||= HudUtility2024.gender_known_ids.map { |id| HudUtility2024.gender_id_to_field_name[id] }
      genders = @gender_fields.select { |f| client.send(f).to_i == 1 }
      genders.count > 1
    end

    private_class_method def self.race_fields(client, exclude: ['HispanicLatinaeo'])
      race_field_keys = ::HudUtility2024.races.keys - exclude
      race_field_keys.select { |f| client.send(f).to_i == 1 }
    end

    private_class_method def self.multi_racial?(client)
      race_fields(client).count > 1
    end

    private_class_method def self.hispanic_latinaeo?(client)
      client.HispanicLatinaeo.to_i == 1
    end

    private_class_method def self.other_than_hispanic_latinaeo?(client)
      race_fields(client, exclude: ['HispanicLatinaeo', 'RaceNone']).count == 1
    end
  end
end
