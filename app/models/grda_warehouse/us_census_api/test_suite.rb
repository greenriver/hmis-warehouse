###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Code initially written for and funded by Delaware Health and Social Services.
# Used and modified with permission.
#
module GrdaWarehouse
  module UsCensusApi
    class TestSuite
      include Aggregates

      def self.run_all!
        @@errors ||= [] # rubocop:disable Style/ClassVars
        @@oks ||= [] # rubocop:disable Style/ClassVars

        TestSuite.new.tap do |suite|
          suite.methods.grep(/^test/).sort.each do |meth|
            suite.send(meth)
          end
        end

        $stdout.print "\n"
        Array.wrap(@@oks).each do |ok|
          $stdout.puts ok
        end
        Array.wrap(@@errors).each do |error|
          $stdout.puts error
        end
      end

      # def test_uniform_names
      #  if UsCensusApi::CensusVariable.where.not(dataset: 'sf1').group(:internal_name).having('count(*) = 1').any?
      #    # sf1 is excluded because the dicennial dataset has variables we don't
      #    # get elsewhere and we only have one year at the moment. After we have
      #    # 2020 data, we might be able to take that bit out.
      #    puts '[FAIL] There should be more than one of each variable since we have many years of data for the acs datasets'
      #  end
      # end

      def test_00_state_chosen
        if ENV['RELEVANT_COC_STATE'].blank?
          $stdout.puts '[FAIL] Set RELEVANT_COC_STATE'
          exit 1
        else
          puts '[OK] state is set'
        end
      end

      def test_non_zeros
        if CensusValue.where('value < 0').any?
          puts '[FAIL] Found a negative census value.'
        else
          puts '[OK] No negative census values.'
        end
      end

      define_method('test_counties') do
        _test_generic_sum!(ALL_PEOPLE, _counties)
      end

      define_method('test_CoC') do
        _test_generic_sum!(ALL_PEOPLE, _cocs)
      end

      define_method('test_zip_codes') do
        _test_generic_sum!(ALL_PEOPLE, _zip_codes)
      end

      # define_method("test_block_groups") do
      #   _test_generic_sum!(ALL_PEOPLE, _block_groups)
      # end

      RACE_ETH.each do |race_eth|
        define_method("test_#{race_eth}_counties") do
          _test_generic_sum!(Aggregates.const_get(race_eth), _counties)
        end

        define_method("test_#{race_eth}_CoC") do
          _test_generic_sum!(Aggregates.const_get(race_eth), _cocs)
        end

        define_method("test_#{race_eth}_zip_codes") do
          _test_generic_sum!(Aggregates.const_get(race_eth), _zip_codes)
        end
      end

      def _test_generic_sum!(var = ALL_PEOPLE, components = _counties)
        # There can be missing data at lower geographies when populations are
        # low, but the total of all the missing values could be significant
        # across the entire state.
        allowed_percent_error = \
          case var.first
          when /WHITE/ then 3
          when /BLACK/ then 3
          when /HISPANIC/ then 5
          when /NOT_HISPANIC/ then 5
          when /ASIAN/ then 10
          when /PACIFIC_ISLANDER/ then 10
          when /OTHER_RACE/ then 10
          when /TWO_OR_MORE_RACES/ then 10
          when /NATIVE_AMERICAN/ then 10
          else
            3
          end

        # We add error in CoC aggregation, so allow more error
        allowed_percent_error *= 2 if components.first.instance_of?(GrdaWarehouse::Shape::Coc)

        error_prone = var.any? { |x| x.match?(/ASIAN|HAWAIIAN|OTHER_RACE|AMERICAN_INDIAN|TWO_OR_MORE/) }

        failure = false
        name = components.first.class.name
        _years.each do |year|
          _states.each do |state|
            total = Finder.new(geometry: state, year: year, internal_names: var).best_value.val

            next if total.zero?

            total_sum = components.sum do |component|
              result = Finder.new(geometry: component, year: year, internal_names: var).best_value
              if result.error
                puts "[WARN] #{name} #{component.id} didn't have a population in #{year} for #{var}"
                failure = true
                0
              else
                result.val
              end
            rescue GrdaWarehouse::UsCensusApi::Finder::CannotFindData
              # These are traditionally small, so it's not really a failure
              unless error_prone
                puts "[WARN] #{name} #{component.id} didn't have a population in #{year} for #{var}"
                failure = true
              end

              0
            end

            error = (total - total_sum).abs / total.to_f * 100
            if error > allowed_percent_error && ! error_prone
              puts "[FAIL] #{name} (for #{var}) didn't sum to state for #{year}: expected #{total.to_i} to equal sum #{total_sum.to_i}. It was off by #{error.round(1)}%"
              failure = true
            end
          end
        end

        puts "[OK] #{name} sums to state" unless failure
      end

      def _states
        Shape::State.my_states
      end

      def _counties
        Shape::County.my_states.select(:id, :full_geoid)
      end

      def _cocs
        Shape::Coc.my_states.select(:id, :full_geoid)
      end

      def _zip_codes
        Shape::ZipCode.my_states.select(:id, :full_geoid)
      end

      def _block_groups
        Shape::BlockGroup.my_states.select(:id, :full_geoid)
      end

      private

      def puts str
        if str.match?(/FAIL/)
          @@errors << str
          $stdout.print('!')
        else
          @@oks << str
          $stdout.print('.')
        end
      end

      # def _process_year_over_year_changes_for(internal_names, what)
      #   populations = _years.map do |year|
      #     _delaware.census_value_sum(year: year, internal_names: internal_names).val
      #   end

      #   stddev = DP::Stats::Calculator.new(populations).stddev
      #   mean = DP::Stats::Calculator.new(populations).mean
      #   z = stddev / mean

      #   if z > 0.1
      #     puts "[FAIL] Year over year stability at state level for #{what}: stdev was #{stddev} and mean was #{mean} and z was #{z}. #{populations}"
      #   else
      #     puts "[OK] Year over year stability at state level for #{what}"
      #     end
      # end

      def _years
        @_years ||= ENV.fetch('US_CENSUS_API_YEARS') { 2012.upto(Date.today.year - 1).map(&:to_s).join(',') }.split(/,/).map(&:to_i)
      end
    end
  end
end
