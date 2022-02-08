###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  module Experiment
    class MetricScoreHistogram
      attr_reader :metric, :pairs, :bins, :stars, :verbose
      def initialize( metric, sample: SimilarityMetric::Experiment.destination_sample, minimum_sample: 100, bins: 20, stars: 20, verbose: true )
        sample          = sample.to_a
        @minimum_sample = minimum_sample
        @metric         = metric
        @bins           = bins
        @stars          = stars
        @verbose        = verbose

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
        puts "collecting scores for #{metric.human_name} (#{metric.type})"
        puts "#{pairs.length} client pairs"
        scores = []
        count = 0;
        t = Time.now
        @pairs.each do |c1, c2|
          s = metric.score( c1, c2 )
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
        puts "#{metric.human_name} (#{metric.type})"
        SimilarityMetric::Experiment.draw_histogram histogram, stars
      end
    end
  end
end
