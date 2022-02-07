###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class Boolean < Multinomial

    DESCRIPTION = <<eos
_{{{human_name}}}_ converts the true/false values in the boolean
HUD field `{{{field}}}` into 0 for same and 1 for different.

In case of a match, the resulting similarity score is multiplied by a factor which varies inversely
with the frequency of the boolean value of the matched category in the population.
This factor is defined as the ratio of the total population size to the size of the
subpopulation expressing the given value of `{{{field}}}`.
To prevent rare values from having an outsize effect, this factor is capped at
{{{max_multiplier}}}.
eos

    def field
      nil
    end

  end
end
