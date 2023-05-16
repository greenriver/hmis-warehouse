###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class MciMapping
    # MCI_RACE = {
    #   '5' => 'Native Hawaiian/Pacific Islander',
    #   '6' => 'Other/Not Volunteered by Recipient',
    #   '2' => 'Black, African American',
    #   '1' => 'White',
    #   '3' => 'American Indian or Alaska Native',
    #   '4' => 'Asian',
    #   '7' => 'Unable to Determine',
    #   '8' => 'Asian Indian',
    #   '9' => 'Japanese',
    #   '10' => 'Chinese',
    #   '11' => 'Korean',
    #   '12' => 'Vietnamese',
    #   '13' => 'Other Asian',
    #   '14' => 'Native Hawaiian',
    #   '15' => 'Guamanian or Chamorro',
    #   '16' => 'Filipino',
    #   '17' => 'Samoan',
    #   '18' => 'Other Pacific Islander',
    #   '19' => 'Other Race',
    #   '20' => 'Did Not Ask',
    #   '21' => 'Declined to Answer',
    #   '24' => 'Unknown - Abandoned/Safe Haven',
    # }.freeze
    MCI_RACE_TO_HUD_RACE = {
      '3' => :AmIndAKNative,
      '4' => :Asian,
      '2' => :BlackAfAmerican,
      '5' => :NativeHIPacific,
      '1' => :White,
    }.freeze
    HUD_RACE_TO_MCI_RACE = MCI_RACE_TO_HUD_RACE.invert.freeze

    def self.mci_races(client)
      mci_races = []
      HudUtility.races.keys.map(&:to_sym).each do |hud_race|
        mci_races.push(HUD_RACE_TO_MCI_RACE[hud_race]) if client.send(hud_race) == 1
      end
      mci_races.compact.map { |s| "#{s}-," }.join('')
    end

    def self.hud_races(mci_race_codes)
      race_fields = HudUtility.races.keys.map { |k| [k.to_sym, nil] }.to_h

      mci_race_codes.split('- ,').each do |mci_race|
        race_fields[MCI_RACE_TO_HUD_RACE[mci_race]] = 1 if MCI_RACE_TO_HUD_RACE.key?(mci_race)
      end
      race_fields
    end

    # MCI_GENDER = {
    #   '1' => 'Male',
    #   '2' => 'Female',
    #   '4' => 'Unknown',
    # }.freeze
    def self.mci_gender(client)
      # Male only
      if client.gender_multi == [1]
        1
      # Female only
      elsif client.gender_multi == [0]
        2
      # Missing or any other gender(s)
      else
        4
      end
    end

    def self.hud_gender_from_text(mci_gender_text)
      gender_fields = HudUtility.gender_fields.map { |k| [k, nil] }.to_h
      gender_fields[:Female] = 1 if mci_gender_text == 'Female'
      gender_fields[:Male] = 1 if mci_gender_text == 'Male'
      gender_fields
    end

    # MCI_ETHNICITY = {
    #   '1' => 'Hispanic',
    #   '2' => 'Not Hispanic, Latino, Or Spanish Origin',
    #   '3' => 'Unable to Determine',
    #   '5' => 'Mexican, Mexican American, Chicano',
    #   '6' => 'Puerto Rican',
    #   '7' => 'Cuban',
    #   '8' => 'Another Hispanic, Latino, Or Spanish Origin',
    # }.freeze
    def self.mci_ethnicity(client)
      if client.ethnicity == 1
        1
      elsif client.ethnicity.zero?
        2
      end
    end
  end
end
