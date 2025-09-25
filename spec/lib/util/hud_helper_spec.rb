###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Tests for the Hud module, specifically for the util method to prove it chooses the correct version
# of the HUD utility, and returns expected results.
RSpec.describe HudHelper do
  describe 'version determination' do
    let(:production_cutoff) { Date.new(2025, 10, 1) }
    let(:staging_cutoff) { Date.new(2025, 9, 1) }

    describe '#hud_csv_version' do
      context 'in production environment' do
        before { allow(Rails.env).to receive(:production?).and_return(true) }

        it 'returns 2024 before October 1, 2025' do
          travel_to(production_cutoff - 1.day) do
            expect(HudHelper.hud_csv_version(force_recalculate: true)).to eq('2024')
          end
        end

        it 'returns 2026 on or after October 1, 2025' do
          aggregate_failures 'production cutoff dates' do
            travel_to(production_cutoff) do
              expect(HudHelper.hud_csv_version(force_recalculate: true)).to eq('2026')
            end

            travel_to(production_cutoff + 1.day) do
              expect(HudHelper.hud_csv_version(force_recalculate: true)).to eq('2026')
            end
          end
        end
      end

      context 'in staging environment ' do
        before do
          allow(Rails.env).to receive(:production?).and_return(false)
          allow(Rails.env).to receive(:staging?).and_return(true)
        end

        it 'returns 2024 before September 1, 2025' do
          travel_to(staging_cutoff - 1.day) do
            expect(HudHelper.hud_csv_version(force_recalculate: true)).to eq('2024')
          end
        end

        it 'returns 2026 on or after September 1, 2025' do
          aggregate_failures 'staging cutoff dates' do
            travel_to(staging_cutoff) do
              expect(HudHelper.hud_csv_version(force_recalculate: true)).to eq('2026')
            end

            travel_to(staging_cutoff + 1.day) do
              expect(HudHelper.hud_csv_version(force_recalculate: true)).to eq('2026')
            end
          end
        end
      end

      context 'in development/test environment' do
        before do
          allow(Rails.env).to receive(:production?).and_return(false)
          allow(Rails.env).to receive(:staging?).and_return(false)
        end

        it 'returns 2026 before September 1, 2025' do
          travel_to(staging_cutoff - 1.day) do
            expect(HudHelper.hud_csv_version(force_recalculate: true)).to eq('2026')
          end
        end

        it 'returns 2026 on or after September 1, 2025' do
          aggregate_failures 'staging cutoff dates' do
            travel_to(staging_cutoff) do
              expect(HudHelper.hud_csv_version(force_recalculate: true)).to eq('2026')
            end

            travel_to(staging_cutoff + 1.day) do
              expect(HudHelper.hud_csv_version(force_recalculate: true)).to eq('2026')
            end
          end
        end
      end
    end

    describe '#util' do
      it 'returns HudUtility2024 when version is 2024' do
        allow(HudHelper).to receive(:current_version).and_return('2024')
        expect(HudHelper.util(force_recalculate: true)).to eq(HudUtility2024)
      end

      it 'returns HudUtility2026 when version is 2026' do
        allow(HudHelper).to receive(:current_version).and_return('2026')
        expect(HudHelper.util(force_recalculate: true)).to eq(HudUtility2026)
      end

      it 'raises error for unknown versions' do
        expect { HudHelper.util('2099') }.to raise_error(RuntimeError, /Unknown HUD utility version: 2099/)
      end
    end

    describe 'method delegation' do
      # pretend to be in production
      before { allow(Rails.env).to receive(:production?).and_return(true) }

      describe 'version-specific method delegation' do
        it 'delegates to correct utility class based on date cutoffs' do
          aggregate_failures 'delegation to HudUtility2024 before cutoff' do
            travel_to(production_cutoff - 1.day) do
              # Verify we get the 2024 utility class
              expect(HudHelper.util(force_recalculate: true)).to eq(HudUtility2024)

              # Test race method delegation
              result = HudHelper.util(force_recalculate: true).race('AmIndAKNative')
              expect(result).to eq('American Indian, Alaska Native, or Indigenous')
              expect(result).to eq(HudUtility2024.race('AmIndAKNative'))

              # Funding sources get special treatment
              result = HudHelper.util(force_recalculate: true).funding_source('HUD: Rural Special NOFO', true)
              expect(result).to eq(55)
              expect(result).to eq(HudHelper.util('2024').funding_source('HUD: Rural Special NOFO', true))
              expect(result).to eq(HudHelper.util('2026').funding_source('HUD: Rural Special NOFO', true))

              result = HudHelper.util(force_recalculate: true).funding_sources
              expect(result).to eq(HudHelper.util('2024').funding_sources)
              expect(result).to_not eq(HudHelper.util('2026').funding_sources)

              # 2024 doesn't have funding_sources_current
              expect { HudHelper.util('2024').funding_sources_current }.to raise_error(NoMethodError)
              expect { HudHelper.util(force_recalculate: true).funding_sources_current }.to raise_error(NoMethodError)
            end
          end

          aggregate_failures 'delegation to HudUtility2026 after cutoff' do
            travel_to(production_cutoff) do
              # Verify we get the 2026 utility class
              expect(HudHelper.util(force_recalculate: true)).to eq(HudUtility2026)

              # Test race method delegation
              result = HudHelper.util(force_recalculate: true).race('AmIndAKNative')
              expect(result).to eq('American Indian, Alaska Native, or Indigenous')
              expect(result).to eq(HudUtility2026.race('AmIndAKNative'))

              # Funding sources get special treatment
              result = HudHelper.util(force_recalculate: true).funding_source('HUD: Rural Special NOFO', true)
              expect(result).to eq(55)
              expect(result).to eq(HudHelper.util('2024').funding_source('HUD: Rural Special NOFO', true))
              expect(result).to eq(HudHelper.util('2026').funding_source('HUD: Rural Special NOFO', true))

              result = HudHelper.util(force_recalculate: true).funding_sources
              expect(result).to_not eq(HudHelper.util('2024').funding_sources)
              expect(result).to eq(HudHelper.util('2026').funding_sources)

              # 2026 has funding_sources_current method
              expect(HudHelper.util('2026')).to respond_to(:funding_sources_current)
              expect(HudHelper.util(force_recalculate: true)).to respond_to(:funding_sources_current)
              expect(HudHelper.util(force_recalculate: true).funding_sources_current.keys).to include(56) # added in 2026
              expect(HudHelper.util('2024').funding_sources.keys).to_not include(56)
              expect(HudHelper.util('2026').funding_sources_current.keys).to include(56)
              expect(HudHelper.util('2026').funding_sources.keys).to include(56)
            end
          end
        end
      end

      it 'passes through keyword arguments correctly' do
        # Test with raise_on_missing: true - should raise error for invalid input
        expect { HudHelper.util(force_recalculate: true).rrh_sub_type_brief('-AmIndAKNative-', raise_on_missing: true) }.to raise_error(RuntimeError)

        # Test with raise_on_missing: false - should return original input for invalid input without raising
        result = HudHelper.util(force_recalculate: true).rrh_sub_type_brief('-AmIndAKNative-', raise_on_missing: false)
        expect(result).to eq('-AmIndAKNative-')

        # Test with valid input - should return translated value
        result = HudHelper.util(force_recalculate: true).rrh_sub_type_brief(1, raise_on_missing: false)
        expect(result).to eq('SSO')
      end
    end

    describe 'method not found handling' do
      it 'raises NoMethodError when method does not exist on target utility' do
        expect { HudHelper.util(force_recalculate: true).nonexistent_method }.to raise_error(NoMethodError)
      end
    end
  end
end
