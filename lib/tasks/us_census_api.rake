namespace :us_census_api do
  desc "Uses the census API to pull down all the variables we need into a usable form and then do some post-processing if needed"
  task :all, [] => [:shapes, :vars, :import, :coc_agg, :summary, :test]

  task :setup, [] => [:environment] do
    @levels = ENV.fetch('US_CENSUS_LEVELS') {
      [
        'STATE',
        'COUNTY',
        'ZCTA5', # zip codes
        'PLACE',
        # 'BG',  # block groups
      ].join(':')
    }.split(":")

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
      GrdaWarehouse::Shape::ZipCode,
      GrdaWarehouse::Shape::Place, # Census designated places, etc. (Towns/Cities)
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

  desc "Output summary of what we've harvested"
  task :summary, [] => [:environment] do
    GrdaWarehouse::UsCensusApi::CensusReview.rebuild!

    result = GrdaWarehouseBase.connection.exec_query(<<~SQL)
      select year,
        SUM(CASE WHEN census_level = 'STATE' THEN 1 ELSE 0 END) AS state_count,
        SUM(CASE WHEN census_level = 'COUNTY' THEN 1 ELSE 0 END) AS county_count,
        SUM(CASE WHEN census_level = 'ZCTA5' THEN 1 ELSE 0 END) AS zip_code_count,
        SUM(CASE WHEN census_level = 'CUSTOM' THEN 1 ELSE 0 END) AS coc_count,
        SUM(CASE WHEN census_level = 'BG' THEN 1 ELSE 0 END) AS block_group_count,
        SUM(CASE WHEN census_level = 'PLACE' THEN 1 ELSE 0 END) AS place_count
      from census_reviews
      group by year
      order by year
    SQL
    puts "Total number of values for each year/geometry(geography)"
    puts "%4s %15s %15s %15s %15s %15s" % ['year', 'state_count', 'county_count', 'zip_code_count', 'coc_count', 'place_count']
    result.each do |row|
      puts "%4d %15d %15d %15d %15d %15d" % [row['year'], row['state_count'], row['county_count'], row['zip_code_count'], row['coc_count'], row['place_count']]
    end
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
