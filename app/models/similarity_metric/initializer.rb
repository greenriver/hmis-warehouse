###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric

  # collect a set of means and standard deviations for a set of metrics given a sample
  class Initializer
    attr_reader :verbose, :minimum_sample, :sample

    # the required parameter is a relation or array holding a bunch of GrdaWarehouse::Hud::Clients
    def initialize( sample: SimilarityMetric::Experiment.destination_sample, verbose: false, minimum_sample: 100 )
      raise "minimum sample size #{minimum_sample} is absurdly small" unless minimum_sample >= 3

      @sample         = sample.to_a
      @verbose        = verbose
      @minimum_sample = minimum_sample
    end

    # collect and save the statistics
    def run!
      puts "finding metrics" if verbose
      Rails.application.eager_load!
      GrdaWarehouseBase.transaction do   # make it safe to kill this thing
        Base.delete_all
        metrics = Base.descendants.map(&:new).reject(&:bogus?).each(&:save!).each(&:prepare!)

        # collect the experimental sample
        puts "collecting sample" if verbose
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

        if verbose
          puts "recalculating statistics for the following metrics: #{metrics.map(&:human_name).to_sentence}."
          puts "#{seen.length} client pairs"
        end
        stats = metrics.map{ |m| [ m, [] ] }.to_h
        count = 0
        seen.each do |c1, c2|
          metrics.each do |m|
            if [ c1, c2 ].all?{ |c| m.quality_data? c } && ( s = m.similarity( c1, c2 ) )
              stats[m] << s
            end
          end
          count += 1
          if verbose && count % 10 == 0
            print '.'
            if count % 1000 == 0
              puts " #{count}"
            end
          end
        end
        puts " #{count}" if verbose && count % 1000 != 0
        stats.select{ |_,values| values.length >= minimum_sample }.each do |m, values|
          m.n                  = values.length
          m.mean               = values.sum.to_f / m.n
          m.standard_deviation = Math.sqrt( values.map{ |v| ( v - m.mean )**2 }.sum / ( m.n - 1 ) )
          m.save!
        end
        if verbose
          metrics.each{ |m| puts "#{m.id} #{m.human_name}: n: #{m.n}; mean: #{m.mean}; standard deviation: #{m.standard_deviation}" }
        end
      end
    end

  end
end
