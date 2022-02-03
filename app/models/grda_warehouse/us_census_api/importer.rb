###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Code initially written for and funded by Delaware Health and Social Services.
# Used and modified with permission.
#
# https://www.census.gov/content/dam/Census/data/developers/api-user-guide/api-guide.pdf
# https://www.census.gov/programs-surveys/geography/guidance/geo-identifiers.html

module GrdaWarehouse
  module UsCensusApi
    class Importer
      attr_accessor :client
      attr_accessor :current_dataset, :current_year
      attr_accessor :current_lookup
      attr_accessor :current_vars
      attr_accessor :current_census_level
      attr_accessor :slice_size
      attr_accessor :datasets
      attr_accessor :years
      attr_accessor :state_fips
      attr_accessor :levels
      attr_accessor :skip_set

      RetryException = Class.new(StandardError)

      # How many variables to get in each request, which might be multiple
      # geographies too. The api is a little dumb in that if it has some of the
      # variables, the whole thing will fail, so we have to back off on this
      # number many times.
      STARTING_SLICE_SIZE = 30

      # How long to wait after each request in seconds
      THROTTLE = 0.75

      def initialize(years: _default_years, datasets: _default_datasets, state_code:, levels: _all_levels)
        self.years = years
        self.datasets = datasets
        self.state_fips = GrdaWarehouse::Shape::State.find_by!(stusps: state_code).geoid
        self.levels = levels & _all_levels
        self.skip_set = Set.new

        if self.levels.empty?
          raise "You likely didn't spell a census level correctly"
        end
      end

      def bootstrap_variables!
        years.each do |year|
          self.current_year = year
          datasets.each do |dataset|
            self.current_dataset = dataset

            next if _bad_combo?

            VariableImporter.new(year: year, dataset: dataset).run!
          end
        end

        RelevantVariables.new.link_up!
      end

      def run!
        _each_where_clause do |where_clause|
          # The gem modifies what we pass in and screws things up, thus the dup.
          results = self.client.where(where_clause.dup)

          if results.is_a?(Hash) && results[:body] && results[:body].to_s.match?(/unsupported geography heirarchy/)
            Rails.logger.warn "Skipping #{where_clause[:level]} within #{where_clause[:within]} as not available for #{self.current_dataset} in #{self.current_year}. Not attempting further queries like this"

            self.skip_set << [
              current_year,
              current_dataset,
              current_census_level
            ]
          elsif results.is_a?(Hash) && results[:code] && self.slice_size == 1
            Rails.logger.info "Cannot get #{where_clause}: #{results[:code]} #{results[:body].to_s}"
          elsif results.is_a?(Hash) && results[:code]
            Rails.logger.debug "Cannot get #{where_clause}: #{results[:body].to_s}. Retrying"
            raise RetryException
          else
            _process_success(results)
          end
        rescue HTTP::ConnectionError
          Rails.logger.error "Retrying query in 30 seconds as it timed out"
          sleep 30
          retry
        end
      end

      # Consider nothing downloaded
      def self.reset!
        CensusVariable.update_all(downloaded: false, internal_name: nil)
        CensusValue.truncate
      end

      private

      def _all_levels
        [
          'STATE',
          'COUNTY',
          'PLACE',
          'SLDU',
          'SLDL',
          'ZCTA5',
          'TRACT',
          'BG',
          'TABBLOCK',
          'CUSTOM',
        ]
      end

      def _default_years
        (Date.today.year-2).downto(2010)
      end

      def _default_datasets
        # acs5: American Community Survey (5 year).
        # acs1: American Community Survey (1 year).
        # sf1/sf2: regular census (2010 for example)
        ['acs5', 'acs1', 'sf1']
      end

      def _bad_combo?
        # Can't have a full census in a non census year:
        if !_full_census_year? && self.current_dataset.match?(/sf\d/)
          return true
        end

        # FIXME:
        # API interface is different (census api gem flops). Need to figure this out.
        if self.current_year == 2011 and self.current_dataset == 'acs1'
          return true
        end

        # Wouldn't have these yet generally.
        if self.current_year >= Date.today.year-1
          return true
        end

        return false
      end

      def _process_success(results)
        now = Date.today
        values = []

        results.each do |result|
          full_geoid   = result.delete("GEO_ID")
          _geo_name    = result.delete("name")
          _state       = result.delete("state")
          _county      = result.delete("county")
          _place       = result.delete("place")
          _tract       = result.delete("tract")
          _block_group = result.delete("block group")
          _block       = result.delete("block")
          _senate      = result.delete("state legislative district (upper chamber)")
          _house       = result.delete("state legislative district (lower chamber)")
          _zip_code    = result.delete("zip code tabulation area")

          result.each do |variable, value|
            if self.current_vars[variable].nil?
              raise "invalid variable: #{variable}"
            end

            # Some years/datasets/vars give us "1234" instead of 1234.
            if value.is_a?(String) && value.match?(/^-?\d+$/)
              value = value.to_i
            end

            if value.is_a?(String) && value.match?(/^-?\d+\.\d+$/)
              value = value.to_f
            end

            if value.is_a?(String)
              binding.pry
            end

            # We don't harvest any value that could be negative.
            # -666666666 shows up as a sentinal sometimes
            if value.present? && value >= 0
              values << [full_geoid, self.current_census_level, value, self.current_vars[variable], now]
            else
              Rails.logger.debug "Nothing for #{variable}"
              # probably too small of a geography to have a value
            end
          end
        end

        CensusValue.import(
          ['full_geoid', 'census_level', 'value', 'census_variable_id', 'created_on'],
          values,
          on_duplicate_key_update: {conflict_target: ['full_geoid', 'census_variable_id'], columns: [:value]},
          raise_error: true
        )

        Rails.logger.debug { "Upserted #{results.flat_map(&:keys).join(',')}" }
        print "."
      end

      # each year/dataset/variable/geography combo roughly speaking
      def _each_where_clause
        years.each do |year|
          self.current_year = year
          self.client = CensusApi::Client.new(ENV['CENSUS_API_KEY'], vintage: year.to_s)
          datasets.each do |dataset|
            self.current_dataset = dataset

            # Only try full census requests on census years (2010, 2020, etc.)
            next if _bad_combo?

            # We don't have the variables.
            if CensusVariable.where(year: self.current_year, dataset: self.current_dataset).none?
              next
            end

            self.client.dataset = dataset

            _specify_vars_we_want

            _query_geo_params.each do |params|
              # only full census ever has block-level data
              next if params[:level] == 'TABBLOCK' && !_full_census_year?

              Rails.logger.info "Doing #{dataset} #{year} for #{params[:level]} within #{params[:within]}"

              self.current_census_level = params[:level].split(/:/).first

              where_clause = params.dup

              self.slice_size = STARTING_SLICE_SIZE
              working = true

              # Attempting to gets values in progressively smaller slices
              while (working) do
                begin
                  self.current_vars.keys.each_slice(self.slice_size) do |vars|
                    where_clause[:fields] = vars + ['GEO_ID']

                    cache_key = Digest::MD5.hexdigest(where_clause.inspect)

                    # enables restarting where we left off
                    if Rails.cache.read(cache_key)
                      print "s"
                      next
                    elsif skip_set.include?([current_year, current_dataset, current_census_level])
                      print "s"
                    else
                      yield where_clause

                      Rails.cache.write(cache_key, 'y', expires_in: 5.days)

                      sleep THROTTLE
                    end

                  end

                  # No RetryExceptions, so we're done with this innner loop
                  working = false
                rescue RetryException
                  if self.slice_size > 1
                    # there was an error, so cut the number of variables in half
                    self.slice_size /= 2

                    Rails.logger.info "Retrying with slices of size #{self.slice_size}"
                  end
                end
              end
            end

            CensusVariable.where(id: self.current_vars.values).update_all(downloaded: true)
          end
        end
      end

      def _specify_vars_we_want
        downloadedness = if ENV['FORCE']=='true'
                           CensusVariable.all
                         else
                           CensusVariable.where(downloaded: false)
                         end

        self.current_vars = CensusVariable.
          with_internal_name.
          merge(downloadedness).
          for_dataset(self.current_dataset).
          for_year(self.current_year).
          pluck(:name, :id).
          to_h
      end

      # All the different geographical conditions
      def _query_geo_params
        return @query_geo_params unless @query_geo_params.nil?

        @query_geo_params = [
          {level: 'COUNTY', within: "STATE:#{state_fips}"},
          {level: "STATE:#{state_fips}" },
          {level: 'PLACE' , within: "STATE:#{state_fips}"},
          {level: 'TRACT' , within: "STATE:#{state_fips}"},
          {level: 'SLDU'  , within: "STATE:#{state_fips}"}, # Senate
          {level: 'SLDL'  , within: "STATE:#{state_fips}"}, # House of Rep
        ]

        GrdaWarehouse::Shape::ZipCode.in_state(state_fips).all.map(&:zcta5ce10).each_slice(50) do |slice|
          @query_geo_params << { level: "ZCTA5:#{slice.join(',')}", within: "STATE:#{state_fips}" }
        end

        GrdaWarehouse::Shape::County.where(statefp: state_fips).find_each do |county|
          # Block Group
          @query_geo_params << {level: 'BG', within: "STATE:#{state_fips}+COUNTY:#{county.countyfp}+TRACT:*"}

          # Block (aka tabulation block)
          @query_geo_params << {level: 'TABBLOCK', within: "STATE:#{state_fips}+COUNTY:#{county.countyfp}+TRACT:*"}
        end

        @query_geo_params.select! do |param|
          self.levels.any? do |level|
            param[:level].starts_with?(level)
          end
        end

        @query_geo_params
      end

      def _full_census_year?
        self.current_year % 10 == 0
      end
    end
  end
end
