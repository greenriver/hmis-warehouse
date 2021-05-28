namespace :us_census_api do
  desc "Uses the census API to pull down all the variables we need into a usable form and then do some post-processing if needed"
  task :all, [] => [:shapes, :vars, :import, :coc_agg, :test]

  task :setup, [] => [:environment] do
    @levels = [
      'STATE',
      'COUNTY',
      'ZCTA5', # zip codes
      # 'BG',  # block groups
    ]

    @state_code = ENV.fetch('RELEVANT_COC_STATE')
    @years = ENV.fetch('US_CENSUS_API_YEARS') { 2012.upto(Date.today.year - 1).map(&:to_s).join(',') }.split(/,/).map(&:to_i)
    @datasets = ENV.fetch('US_CENSUS_API_DATASETS') { 'acs5' }.split(/,/).filter { |d| d.match(/acs5|sf1/) }
  end

  desc "Ensure shapes have full geoid so they can be linked to the census values"
  task :shapes, [] => [:environment] do
    [
      GrdaWarehouse::Shape::BlockGroup,
      GrdaWarehouse::Shape::CoC,
      GrdaWarehouse::Shape::County,
      GrdaWarehouse::Shape::State,
      GrdaWarehouse::Shape::ZipCode
    ].each do |klass|
      klass.set_full_geoid!
      klass.simplify!
    end
  end

  desc "Get the available variables from the US Census"
  task :vars, [] => [:setup, :environment] do
    importer = GrdaWarehouse::UsCensusApi::Importer.new(years: @years, datasets: @datasets, state_code: @state_code, levels: @levels)
    importer.bootstrap_variables!
  end

  desc "Get data from the US Census"
  task :import, [] => [:setup, :environment] do
    importer = GrdaWarehouse::UsCensusApi::Importer.new(years: @years, datasets: @datasets, state_code: @state_code, levels: @levels)
    importer.run!
  end

  desc "Aggregate values so CoC geometries can use same interface to census data"
  task :coc_agg, [] => [:setup, :environment] do
    GrdaWarehouse::UsCensusApi::CoCAgg.run!
  end

  desc "Run some computations that sanity check the values"
  task :test, [] => [:environment] do |t, args|
    GrdaWarehouse::UsCensusApi::TestSuite.run_all!
  end

  desc "debug"
  task :debug, [] => [:environment] do
    report = PublicReports::HomelessPopulation.find(2)

    report.instance_eval do
      @debug = true
    end

    report.send(:race_chart, :overall)
  end
end
