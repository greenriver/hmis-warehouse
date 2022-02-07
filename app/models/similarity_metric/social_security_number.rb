###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class SocialSecurityNumber < Base

    FAKES_RX = /   # not using HUD::valid_social? because I think it's too strict for matching purposes
      \A
        (?:
          ([2-9])\1*
          |
          0
            (:?
              0*
              |
              78051120
            )
          |
          1
            (?:
              1*
              |
              (?:2(?:3(?:4(?:5(?:6(?:7(?:89?)?)?)?)?)?)?)?
            )
        )
      \z
    /x

    def field
      :SSN
    end

    def quality_data?(client)
      self.class.quality_data? client
    end

    def similarity(c1, c2)
      Text::Levenshtein.distance c1.SSN, c2.SSN
    end

    def self.valid_ssn?(str, allow_last_4: true)
      if str.nil?
        false
      elsif allow_last_4 && str.length == 4 && str != '0000'
        true
      elsif allow_last_4 && str.starts_with?('00000') && str != '000000000'
        true
      elsif str.length != 9
        false
      elsif str.starts_with?('9')
        false
      elsif str.starts_with?('000')
        false
      elsif str.starts_with?('666')
        false
      else
        true
      end
    end

    def self.quality_data?(client)
      valid_ssn? client.SSN
    end
  end
end
