namespace :us_census_api do
  desc "Uses the census API to pull down all the variables we need into a usable form and then do some post-processing if needed"
  task :all, [] => [:shapes, :vars, :import, :coc_agg, :test]

  task :setup, [] => [:environment] do
    @levels = [
      'STATE',
      'COUNTY',
      'ZCTA5',
      'BG',
    ]

    @state_code = ENV.fetch('RELEVANT_COC_STATE')
    #@years = 2010.up_to(Date.today.year - 1)
    #@datasets = ['acs5', 'sf1', 'acs1']
    @years = ENV.fetch('US_CENSUS_API_YEARS') { '2019' }.split(/,/).map(&:to_i)
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

  desc "Example"
  task :example, [] => [:environment] do
    census_data = {}
    scope = GrdaWarehouse::Shape::CoC.limit(2)
    full_census_count = scope.map(&:population).map(&:val).sum

    include GrdaWarehouse::UsCensusApi::Aggregates

    ::HUD.races(multi_racial: true).each do |key, label|
      #puts key
      #puts label

      # We can make the finder class understand/translate codes
      # see the include above for where these came from
      race_var = case key
                 when 'AmIndAKNative' then NATIVE_AMERICAN
                 when 'Asian' then ASIAN
                 when 'BlackAfAmerican' then BLACK
                 when 'NativeHIOtherPacific' then PACIFIC_ISLANDER
                 when 'White' then WHITE

                 # Does RaceNone mean unknown or none of the above?
                   # This might be wrong...
                 when 'RaceNone' then OTHER_RACE

                 when 'MultiRacial' then TWO_OR_MORE_RACES
                 else
                   raise "unknown race found"
                 end

      census_data[label] = 0

      census_data[label] = scope
        # need to handle missing populations, but this is the idea...
        .map { |coc| coc.population(internal_names: race_var).val }
        .sum / full_census_count.to_f if full_census_count&.positive?
    end

    puts census_data.ai
  end
end
