###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class Gender < Multinomial

    DESCRIPTION = <<END
*{{{human_name}}}* is a complex property stored in HUD data as a multinomial
category in the field `{{{field}}}` with 9 values, including the null value.
For the purposes of measuring gender similarity we use the following supercategories:

* female
* male
* transgender
* questioning
* none: HUD's "Doesn’t identify as male, female, or transgender" and "Client doesn’t know"
* not collected: null, "Client refused", and "Data not collected"

In case of a match, the resulting similarity score is multiplied by a factor which varies inversely
with the frequency of the category in the population. This factor is defined as the ratio
of the total population size to the size of the subpopulation expressing the given subcategory.
To prevent odd categories from having an outsize effect, this factor is capped at
{{{max_multiplier}}}.
END

    def bogus?
      true # pulled out of calculations with changes from 2022 HMIS spec
    end

    def field
      :Gender
    end

    def group(k)
      case k
      when 0, 1, 2, 3
        k
      when 4, 8
        4
      when nil, 9, 99
        nil
      else
        raise "unexpected gender value: #{k}"
      end
    end
  end
end
