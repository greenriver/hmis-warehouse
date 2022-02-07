###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  module Experiment
    class ScoreHistogram
      attr_reader :pairs, :bins, :stars, :metrics, :verbose
      def initialize( sample: SimilarityMetric.sample, pairs_per_client: sample.count - 1, minimum_sample: 100, bins: 20, stars: 20, verbose: true )
        sample            = sample.to_a
        @pairs_per_client = pairs_per_client
        @minimum_sample   = minimum_sample
        @metrics          = ::SimilarityMetric::Base.usable.all.reject(&:bogus?)
        @bins             = bins
        @stars            = stars
        @verbose          = verbose

        # collect the experimental sample
        puts "collecting sample"
        seen  = Set.new
        count = 0
        sample.each do |client|
          excludables = client.source_clients.map(&:id)
          client.source_clients.each do |client|
            client.merge_candidates.where.not( id: excludables ).limit(500).to_a.each do |candidate|
              count += 1
              if verbose && count % 10 == 0
                print '.'
                if count % 1000 == 0
                  puts " #{count}"
                end
              end
              seen <<[ candidate, client ].sort_by(&:id)
            end
          end
        end
        puts " #{count}" if verbose && count % 1000 != 0
        @pairs = seen.to_a
      end

      def run!
        if @pairs.empty?
          puts "no scores collected"
          return
        end
        puts "collecting weighted scores"
        puts "#{pairs.length} client pairs"
        scores = []
        count = 0;
        t = Time.now
        @pairs.each do |c1, c2|
          s = SimilarityMetric.single_score c1, c2, metrics: metrics
          scores << s unless s.nil?
          if ( count += 1 ) % 10 == 0
            print '.'
            if count % 1000 == 0
              puts " #{count}"
            end
          end
        end
        t = Time.now - t
        puts " #{count}" unless count % 1000 == 0
        puts "#{t} seconds; #{t.to_f / @pairs.length} seconds per score"
        puts "binning scores..."
        histogram = SimilarityMetric::Experiment.histogram bins, scores
        SimilarityMetric::Experiment.draw_histogram histogram, stars
      end
    end
  end
end
