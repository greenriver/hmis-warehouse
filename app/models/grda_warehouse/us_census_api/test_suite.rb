###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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
        @@errors ||= []
        @@oks ||= []

        TestSuite.new.tap do |suite|
          suite.methods.grep(/^test/).sort.each do |meth|
            suite.send(meth)
          end
        end

        STDOUT.print "\n"
        Array.wrap(@@oks).each do |ok|
          STDOUT.puts ok
        end
        Array.wrap(@@errors).each do |error|
          STDOUT.puts error
        end
      end

      #def test_uniform_names
      #  if UsCensusApi::CensusVariable.where.not(dataset: 'sf1').group(:internal_name).having('count(*) = 1').any?
      #    # sf1 is excluded because the dicennial dataset has variables we don't
      #    # get elsewhere and we only have one year at the moment. After we have
      #    # 2020 data, we might be able to take that bit out.
      #    puts '[FAIL] There should be more than one of each variable since we have many years of data for the acs datasets'
      #  end
      #end

      def test_00_state_chossen
        if ENV['RELEVANT_COC_STATE'].blank?
          $stdout.puts "[FAIL] Set RELEVANT_COC_STATE"
          exit 1
        else
          puts "[OK] state is set"
        end
      end

      def test_non_zeros
        if CensusValue.where("value < 0").any?
          puts "[FAIL] Found a negative census value."
        else
          puts "[OK] No negative census values."
        end
      end

      define_method("test_counties") do
        _test_generic_sum!(ALL_PEOPLE, _counties)
      end

      define_method("test_CoC") do
        _test_generic_sum!(ALL_PEOPLE, _cocs)
      end

      define_method("test_zip_codes") do
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

      def _test_generic_sum!(var=ALL_PEOPLE, components=_counties)
        failure = false
        name = components.first.class.name
        _years.each do |year|
          total = Finder.new(geometry: _state, year: year, internal_names: var).best_value.val

          total = components.sum do |component|
            result = Finder.new(geometry: component, year: year, internal_names: var).best_value
            if result.error
              if component.id == 3311 && var == ["POP::ASIAN_ALONE"]
                binding.irb
                exit
              end
              puts "[FAIL] #{name} #{component.id} didn't have a population in #{year} for #{var}"
              failure = true
              0
            else
              result.val
            end
          end

          if total != (total)
            puts "[FAIL] #{name} didn't sum to state for #{year}: #{(total.to_i - total.to_i).abs}"
            failure = true
          end
        end

        puts "[OK] #{name} sums to state" unless failure
      end

      def _state
        Shape::State.my_state.first
      end

      def _counties
        Shape::County.my_state.select(:id, :full_geoid)
      end

      def _cocs
        Shape::CoC.my_state.select(:id, :full_geoid)
      end

      def _zip_codes
        Shape::ZipCode.my_state.select(:id, :full_geoid)
      end

      def _block_groups
        Shape::BlockGroup.my_state.select(:id, :full_geoid)
      end

      private

      def puts str
        if str.match?(/FAIL/)
          @@errors << str
          STDOUT.print('!')
        else
          @@oks << str
          STDOUT.print('.')
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
