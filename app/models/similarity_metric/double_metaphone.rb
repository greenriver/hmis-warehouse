###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class DoubleMetaphone < Field

    DESCRIPTION = <<END
_{{{human_name}}}_ converts the string stored in HUD's `{{{field}}}` field
into a form that roughly reflects the sound of the word and uses the Levenshtein
edit distance algorithm then to determine the rough phonetic similarity of both
`{{{field}}}`s.
END
    def similarity(c1, c2)
      if ( s1 = c1.send(field).presence ) && ( s2 = c2.send(field).presence )
        m1, m2 = [ s1, s2 ].map{ |s| Text::Metaphone.double_metaphone s }.map(&:compact)
        m1.product(m2).map{ |s1, s2| Text::Levenshtein.distance s1, s2 }.min
      end
    end
  end
end
