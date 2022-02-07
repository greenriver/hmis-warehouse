###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class DateOfBirth < Base

    DESCRIPTION = <<END
*{{{human_name}}}* measures the similarity of two individuals by comparing
how similar their dates of birth are to the dates of birth of arbitrary pairs
of individuals taken from a reference population.
END

    def quality_data?(client)
      return client.DOB.present?

      # we are ditching this for now
      if q = client.DOBDataQuality
        !( q == 9 || q == 99 )
      else
        true
      end
    end

    def similarity(c1, c2)
      d1, d2 = c1.DOB, c2.DOB
      return nil unless d1.present? && d2.present?
      ( d1.to_time.to_i - d2.to_time.to_i ).abs
    end

    def field
      :DOB
    end

    def human_name
      "Date of Birth"
    end
  end
end
