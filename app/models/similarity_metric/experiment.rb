###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  # some functions commonly used by experiments
  module Experiment
    module_function

    # bin up scores into a histogram with `bins` bins
    def histogram(bins, scores)
      raise "no scores" if scores.empty?
      min = scores.min
      max = scores.max
      bin_size = ( max - min ) / bins
      lim = min + bin_size
      bin_map = {}
      bins.times do |i|
        s, e = min, min += bin_size
        range = if i == bins - 1
          s..e
        else
          s...e
        end
        bin_map[range] = 0
      end
      bins = bin_map.keys
      bin = bins.shift
      previous = nil
      scores.sort.each do |s|
        unless bin.include? s
          previous = bin
          bin = bins.shift || previous    # this is necessary because of floating point monkey business
        end
        bin_map[bin] += 1
      end
      bin_map
    end

    # print binned up data into a nice histogram
    def draw_histogram(h, stars)
      formatter = Range === h.keys.first ? RangeFormatter : IntegerFormatter
      formatter = formatter.new h.keys
      cs = -> (v) { Array === v ? v : [ v, v ] }
      max_count = h.values.map{ |v| cs.(v).first }.max
      position = h.values.map{ |v| cs.(v).last }
      velocity = {}.tap do |velocity|
        position.each_with_index do |v,i|
          if i > 0
            velocity[i] = position[i] - position[i - 1]
          end
        end
      end
      acceleration = {}.tap do |dd|
        velocity.each do |i, v|
          if i > 1
            dd[i] = v - velocity[i - 1]
          end
        end
      end
      count_formatter, delta_formatter, acc_formatter = [ position, velocity.values, acceleration.values ].map do |values|
        f = Integer === values.first ? IntegerFormatter : FloatFormatter
        f.new values
      end
      star_size = max_count / stars.to_f
      h.each_with_index do |(range, count), i|
        count, show = cs.(count)
        print formatter.format(range)
        print ' '
        nstars = ( count / star_size ).ceil
        nstars = stars if nstars > stars   # prevent floating point shenanigans
        nspaces = stars - nstars
        nstars.times{ print '*' }
        nspaces.times{ print ' ' }
        print ' '
        print count_formatter.format(show)
        if v = velocity[i]
          print " (#{delta_formatter.format(v)})"
        end
        if v = acceleration[i]
          print " (#{acc_formatter.format(v)})"
        end
        print "\n"
      end
    end

    # obtain a random sample of destination clients
    def destination_sample(size=500)
      GrdaWarehouse::Hud::Client.destination.random.limit(size).preload(:source_clients)
    end

    # obtain a random sample of source clients
    def source_sample(size=500)
      GrdaWarehouse::Hud::Client.source.random.limit(size)
    end
  end
end
