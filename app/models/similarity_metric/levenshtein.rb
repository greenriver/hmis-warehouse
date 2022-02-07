###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class Levenshtein < Field

    DESCRIPTION = <<eos
_{{{human_name}}}_ computes the Levenshtein distance between
the values of the `{{{field}}}` attribute of two clients as represented
in the HUD database. If one or the other client does not have a defined
`{{{field}}}`, no similarity is calculated.
eos

    def similarity(c1, c2)
      lev c1, c2, field
    end

    protected

      def lev( c1, c2, field )
        if field
          if ( s1 = c1.send(field).presence ) && ( s2 = c2.send(field).presence )
            Text::Levenshtein.distance s1.downcase, s2.downcase
          end
        end
      end

  end
end
