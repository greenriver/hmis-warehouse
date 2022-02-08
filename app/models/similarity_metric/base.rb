###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class Base < ApplicationRecord
    self.table_name = :similarity_metrics

    scope :usable, -> { where arel_table[:n].gt(0).and( arel_table[:weight].gt 0 ) }

    MD = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML,
      autolink:  true,
      hard_wrap: false,
      quote: true
    )

    # override this as appropriate in subclasses
    DESCRIPTION = <<eos
*{{{human_name}}}* does not yet have a description.
eos

    # take to clients and return a number to be used in ranking; more similar pairs should map to smaller numbers
    # should return nil if the clients aren't comparable by this metric
    def similarity(c1, c2)
      raise NotImplementedError
    end

    # a description of this metric for display
    def description
      @description ||= begin
        str = self.class::DESCRIPTION.gsub /[{]{3}([a-z]\w*)[}]{3}/ do
          method = Regexp.last_match[1]
          send(method)
        end
        MD.render(str).strip.html_safe
      end
    end

    # returns the weight times the z-score of the similarity of these two clients using this metric
    # this is the normalized and weighted similarity to be used in aggregating metrics for ranking
    def score(c1, c2)
      if quality_data?(c1) && quality_data?(c2)
        if s = similarity( c1, c2 )
          weight * ( s - mean ) / standard_deviation
        end
      end
    end

    def quality_data?(client)
      true
    end

    # for displaying in forms
    def human_name
      @human_name ||= self.class.name.gsub( /\A.*::/, '' ).underscore.titleize
    end

    def prepare!
      # do nothing
    end

    def initialized?
      n > 0
    end

    def bogus?
      self.class == Base
    end
  end
end
