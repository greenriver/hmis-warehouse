namespace :us_census_api do
  desc "Uses the census API to pull down all the variables we need into a usable form and then do some post-processing if needed"
  # NOTE: you can check the status of the data in the database with
  #  bin/rake us_census_api:summary
  # If for whatever reason it isn't adding a particular year, you may need to
  # call it with a single year specified, and if that fails, add FORCE to rebuild
  # it caches which years it has tried and assumes they are complete, FORCE will
  # overwrite no matter what
  # FORCE=true US_CENSUS_API_YEARS=2015 bin/rake us_census_api:all
  task :all, [] => [:shapes, :vars, :import, :coc_agg, :town_agg, :summary, :test]

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

    @state_codes = ENV.fetch('RELEVANT_COC_STATE').split(',')
    @years = ENV.fetch('US_CENSUS_API_YEARS') { 2012.upto(Date.today.year - 2).map(&:to_s).join(',') }.split(/,/).map(&:to_i)
    @datasets = ENV.fetch('US_CENSUS_API_DATASETS') { 'acs5' }.split(/,/).filter { |d| d.match(/acs5|sf1/) }
  end

  desc "Ensure shapes have full geoid so they can be linked to the census values"
  task :shapes, [] => [:environment] do
    [
      GrdaWarehouse::Shape::BlockGroup,
      GrdaWarehouse::Shape::Coc,
      GrdaWarehouse::Shape::County,
      GrdaWarehouse::Shape::State,
      GrdaWarehouse::Shape::ZipCode,
      GrdaWarehouse::Shape::Place, # Census designated places, etc. (Towns/Cities)
      GrdaWarehouse::Shape::Town, # must be fetched from individual states
    ].each do |klass|
      klass.set_full_geoid!
      klass.simplify!
    end
  end

  desc "Get the available variables from the US Census"
  task :vars, [] => [:setup, :environment] do
    @state_codes.each do |state_code|
      importer = GrdaWarehouse::UsCensusApi::Importer.new(years: @years, datasets: @datasets, state_code: state_code, levels: @levels)
      importer.bootstrap_variables!
    end
  end

  desc "Get data from the US Census"
  task :import, [] => [:setup, :environment] do
    @state_codes.each do |state_code|
      importer = GrdaWarehouse::UsCensusApi::Importer.new(years: @years, datasets: @datasets, state_code: state_code, levels: @levels)
      importer.run!
    end
  end

  desc "Aggregate values so CoC geometries can use same interface to census data"
  task :coc_agg, [] => [:setup, :environment] do
    GrdaWarehouse::UsCensusApi::CocAgg.run!
  end

  desc "Aggregate values so Town geometries can use same interface to census data"
  task :town_agg, [] => [:setup, :environment] do
    GrdaWarehouse::UsCensusApi::TownAgg.run!
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
        SUM(CASE WHEN census_level = 'PLACE' THEN 1 ELSE 0 END) AS place_count,
        SUM(CASE WHEN census_level = 'CUSTOMTOWN' THEN 1 ELSE 0 END) AS town_count
      from census_reviews
      group by year
      order by year
    SQL
    puts "Total number of values for each year/geometry(geography)"
    puts "%4s %15s %15s %15s %15s %15s %15s" % ['year', 'state_count', 'county_count', 'zip_code_count', 'coc_count', 'place_count', 'town_count']
    result.each do |row|
      puts "%4d %15d %15d %15d %15d %15d  %15d" % [row['year'].presence || 0, row['state_count'].presence || 0, row['county_count'].presence || 0, row['zip_code_count'].presence || 0, row['coc_count'].presence || 0, row['place_count'].presence || 0, row['town_count'].presence || 0]
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
