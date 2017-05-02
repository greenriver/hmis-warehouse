namespace :similarity do

  desc "BATCH_SIZE=10000 destination clients to try; THRESHOLD=-1.45 lower numbers are stronger matches"
  task :generate_candidates => [:environment] do |task, args|
    opts = {
      threshold: ENV['THRESHOLD'].presence || -1.45,
      batch_size: ENV['BATCH_SIZE'].presence || 10000,
      run_length: ENV['RUN_LENGTH'].presence || 240, # Run for a max of 4 hours
    }
    SimilarityMetric::Tasks::GenerateCandidates.new(batch_size: opts[:batch_size], threshold: opts[:threshold], run_length: opts[:run_length]).run!
  end

  desc "initialize similarity metrics, collecting necessary statistics and saving them to db; defaults: n=200, verbose=true"
  task :initialize, [:n,:verbose] => [:environment] do |task, args|
    n       = ( args.n || 200 ).to_i
    verbose = ( args.verbose || 'true' ) == 'true'
    if verbose
      puts "n: #{n}; verbose: #{verbose}"
    end
    sample = SimilarityMetric::Experiment.destination_sample n
    SimilarityMetric::Initializer.new( sample: sample, verbose: verbose ).run!
  end

  desc "list initialized metrics used in scoring; metrics are ranked by likelihood of applicabilty and name"
  task :list => [:environment] do
    SimilarityMetric::Base.all.reject(&:bogus?).select(&:initialized?).sort do |a,b|
      c = a.n - b.n
      if c < 0
        1
      elsif c > 0
        -1
      elsif a.type < b.type
        -1
      else
        1
      end
    end.each do |m|
      puts "#{m.human_name}\t\t\t#{m.type}"
    end
  end

  namespace :experiment do

    desc "for a random sample of individuals, show the scores of the top matches; defaults: n=10, n_top=20, threshold=0"
    task :show_scores, [:n, :n_top, :threshold] => [:environment] do |task, args|
      n     = ( args.n || 10 ).to_i
      n_top = ( args.n_top || 20 ).to_i
      threshold = args.threshold.to_f
      metrics = SimilarityMetric::Base.usable.all.reject(&:bogus?)
      puts "
For a random sample of #{n} individuals we will show the top #{n_top} matching individuals along with
their scores. Lower scores indicate a better match. The threshold is #{threshold}. The metrics used are:

#{ metrics.map(&:type).to_sentence.gsub /SimilarityMetric::/, '' }

Targets are destination clients. Source clients already linked to the target are excluded. For every target the
candidates chosen for all its source clients are chosen.

data is shown as (<ID>)\t<NAME> -- <SSN>\t\t<SCORE>
"
      SimilarityMetric::Experiment.destination_sample(n).each do |client|
        puts "\ntarget: (#{client.id}) #{client.name} -- #{client.SSN}\nsource_clients: #{client.source_clients.sort.map(&:id).to_sentence}"
        puts "==========\n"
        score_map = SimilarityMetric.candidates(client)
        score_map.keys.sort_by{ |c| score_map[c] }[0...n_top].each do |c|
          puts "\t(#{c.id})\t#{c.name} -- #{c.SSN}\t\t#{score_map[c]}"
        end
      end
    end

    desc "create a score histogram; metrics: FirstName, SocialSecurityNumber, etc.; defaults: bins=20, columns=20, sample_size=200"
    task :metric_histogram, [:metric, :bins, :columns, :sample_size] => [:environment] do |task, args|
      raise "metric required" unless args.metric
      metric = SimilarityMetric::Base.where( type: "SimilarityMetric::#{args.metric}" ).first or raise "no metric #{args.metric}"
      bins        = ( args.bins || 20 ).to_i
      stars       = ( args.columns || 20 ).to_i
      sample_size = ( args.sample_size || 200 ).to_i
      raise "all numeric parameters must be greater than 1" if [ bins, stars, sample_size ].any?{ |m| m < 2 }

      sample = SimilarityMetric::Experiment.destination_sample sample_size
      x = SimilarityMetric::Experiment::MetricScoreHistogram.new metric, sample: sample, stars: stars, bins: bins
      puts "#{metric.human_name}: #{metric.type}"
      x.run!
    end

    desc "create a score histogram for weighted scores using all available metrics; defaults: bins=20, columns=20, sample_size=200"
    task :histogram, [:bins, :columns, :sample_size] => [:environment] do |task, args|
      bins        = ( args.bins || 20 ).to_i
      stars       = ( args.columns || 20 ).to_i
      sample_size = ( args.sample_size || 200 ).to_i
      raise "all numeric parameters must be greater than 1" if [ bins, stars, sample_size ].any?{ |m| m < 2 }

      sample = SimilarityMetric::Experiment.destination_sample sample_size
      x = SimilarityMetric::Experiment::ScoreHistogram.new sample: sample, stars: stars, bins: bins
      x.run!
    end

    desc "find the top merge candidates for a sample of destination clients and average the scores for the top ranks; defaults: bins=20, columns=20, sample_size=100, threshold=-0.9"
    task :ranking, [:sample_size, :threshold, :bins, :columns] => [:environment] do |task, args|
      bins        = ( args.bins || 30 ).to_i
      stars       = ( args.columns || 20 ).to_i
      sample_size = ( args.sample_size || 100 ).to_i
      threshold   = ( args.threshold || -0.9 ).to_f
      raise "all integer parameters must be greater than 1" if [ bins, stars, sample_size ].any?{ |m| m < 2 }

      x = SimilarityMetric::Experiment::Ranking.new n: sample_size, stars: stars, bins: bins, threshold: threshold
      x.run!
    end
  end
end