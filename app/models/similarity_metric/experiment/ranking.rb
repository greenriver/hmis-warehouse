###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  module Experiment

    # experiment to see how the top scores typically line up for a client
    class Ranking
      attr_reader :bins, :stars, :sample, :threshold, :n

      def initialize( n: 100, bins: 30, stars: 20, threshold: 0 )
        @bins = bins
        @stars = stars
        @sample = SimilarityMetric::Experiment.destination_sample.limit(n).all
        @threshold = threshold
        @n = n
      end

      def run!
        bin_bin = bins.times.map{[]}
        puts "collecting data"
        puts "NOTE: this will be slow"
        puts "target clients: #{n}; maximum merge candidates: #{bins}; score threshold: #{threshold}"
        puts "Any apparent mis-ranking that may occur is an artifact of averaging over individuals with different numbers of merge candidates."
        count = 0;
        metrics = SimilarityMetric::Base.usable.all.reject(&:bogus?)
        t = Time.now
        sample.each do |client|
          score_map = SimilarityMetric.candidates( client, metrics: metrics, threshold: threshold, use_zero_crossing: false )
          candidates = score_map.keys.sort_by{ |c| score_map[c] }[0...bins]
          candidates.each_with_index do |c, i|
            bin_bin[i] << score_map[c]
          end
          print '.'
          if ( count += 1 ) % 100 == 0
            puts " #{count}"
          end
        end
        unless count % 100 == 0
          puts " #{count}"
        end
        t = Time.now - t
        puts "#{t} seconds; #{t.to_f / count} seconds per client"
        histogram = {}
        bin_bin.each_with_index do |scores, idx|
          break if scores.empty?
          histogram[idx] = scores.sum / scores.length
        end
        min, max = histogram.values.min, histogram.values.max
        delta = ( max - min ).abs / stars
        histogram = histogram.map do |k,v|
          d = ( max - v ).abs
          [ k, [ ( d / delta ).round, v ] ]
        end.to_h
        SimilarityMetric::Experiment.draw_histogram histogram, stars
      end
    end
  end
end
