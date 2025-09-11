# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudUtilityCurrent do
  describe 'version determination' do
    let(:production_cutoff) { Date.new(2025, 10, 1) }
    let(:staging_cutoff) { Date.new(2025, 9, 1) }

    describe '#hud_csv_version' do
      context 'in production environment' do
        before { allow(Rails.env).to receive(:production?).and_return(true) }

        it 'returns 2024 before October 1, 2025' do
          travel_to(production_cutoff - 1.day) do
            expect(HudUtilityCurrent.hud_csv_version).to eq('2024')
          end
        end

        it 'returns 2026 on or after October 1, 2025' do
          aggregate_failures 'production cutoff dates' do
            travel_to(production_cutoff) do
              expect(HudUtilityCurrent.hud_csv_version).to eq('2026')
            end

            travel_to(production_cutoff + 1.day) do
              expect(HudUtilityCurrent.hud_csv_version).to eq('2026')
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
            expect(HudUtilityCurrent.hud_csv_version).to eq('2024')
          end
        end

        it 'returns 2026 on or after September 1, 2025' do
          aggregate_failures 'staging cutoff dates' do
            travel_to(staging_cutoff) do
              expect(HudUtilityCurrent.hud_csv_version).to eq('2026')
            end

            travel_to(staging_cutoff + 1.day) do
              expect(HudUtilityCurrent.hud_csv_version).to eq('2026')
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
            expect(HudUtilityCurrent.hud_csv_version).to eq('2026')
          end
        end

        it 'returns 2026 on or after September 1, 2025' do
          aggregate_failures 'staging cutoff dates' do
            travel_to(staging_cutoff) do
              expect(HudUtilityCurrent.hud_csv_version).to eq('2026')
            end

            travel_to(staging_cutoff + 1.day) do
              expect(HudUtilityCurrent.hud_csv_version).to eq('2026')
            end
          end
        end
      end
    end

    describe '#current_hud_utility' do
      it 'returns HudUtility2024 when version is 2024' do
        allow(HudUtilityCurrent).to receive(:hud_csv_version).and_return('2024')
        expect(HudUtilityCurrent.current_hud_utility).to eq(HudUtility2024)
      end

      it 'returns HudUtility2026 when version is 2026' do
        allow(HudUtilityCurrent).to receive(:hud_csv_version).and_return('2026')
        expect(HudUtilityCurrent.current_hud_utility).to eq(HudUtility2026)
      end

      it 'defaults to HudUtility2026 for unknown versions' do
        allow(HudUtilityCurrent).to receive(:hud_csv_version).and_return('2099')
        expect(HudUtilityCurrent.current_hud_utility).to eq(HudUtility2026)
      end
    end

    describe 'method delegation' do
      # pretend to be in production
      before { allow(Rails.env).to receive(:production?).and_return(true) }
      describe 'successful method delegation' do
        it 'delegates to HudUtility2024 when version is 2024' do
          travel_to(production_cutoff - 1.day) do
            result = HudUtilityCurrent.race('AmIndAKNative')
            expect(result).to eq('American Indian, Alaska Native, or Indigenous')
            expect(result).to eq(HudUtility2024.race('AmIndAKNative'))

            # Funding sources get special treatment
            result = HudUtilityCurrent.funding_source('HUD: Rural Special NOFO', true)
            expect(result).to eq(55)
            expect(result).to eq(HudUtility2024.funding_source('HUD: Rural Special NOFO', true))
            expect(result).to eq(HudUtility2026.funding_source('HUD: Rural Special NOFO', true))

            result = HudUtilityCurrent.funding_sources
            expect(result).to eq(HudUtility2024.funding_sources)
            expect(result).to_not eq(HudUtility2026.funding_sources)

            # 2024 doesn't have funding_sources_current
            expect { HudUtility2024.funding_sources_current }.to raise_error(NoMethodError)
            expect { HudUtilityCurrent.funding_sources_current }.to raise_error(NoMethodError)
          end
        end

        it 'delegates to HudUtility2026 when version is 2026' do
          travel_to(production_cutoff) do
            result = HudUtilityCurrent.race('AmIndAKNative')
            expect(result).to eq('American Indian, Alaska Native, or Indigenous')
            expect(result).to eq(HudUtility2026.race('AmIndAKNative'))

            # Funding sources get special treatment
            result = HudUtilityCurrent.funding_source('HUD: Rural Special NOFO', true)
            expect(result).to eq(55)
            expect(result).to eq(HudUtility2024.funding_source('HUD: Rural Special NOFO', true))
            expect(result).to eq(HudUtility2026.funding_source('HUD: Rural Special NOFO', true))

            result = HudUtilityCurrent.funding_sources
            expect(result).to_not eq(HudUtility2024.funding_sources)
            expect(result).to eq(HudUtility2026.funding_sources)

            # 2024 doesn't have funding_sources_current
            expect { HudUtility2026.funding_sources_current }.to_not raise_error(NoMethodError)
            expect { HudUtilityCurrent.funding_sources_current }.to_not raise_error(NoMethodError)
            expect(HudUtilityCurrent.funding_sources_current.keys).to include(56) # added in 2026
            expect(HudUtility2024.funding_sources.keys).to_not include(56)
            expect(HudUtility2026.funding_sources_current.keys).to include(56)
            expect(HudUtility2026.funding_sources.keys).to include(56)
          end
        end
      end

      it 'passes through keyword arguments and blocks' do
        expect { HudUtilityCurrent.rrh_sub_type_brief('-AmIndAKNative-', raise_on_missing: true) }.to raise_error(RuntimeError)
        expect { HudUtilityCurrent.rrh_sub_type_brief('-AmIndAKNative-', raise_on_missing: false) }.to_not raise_error(RuntimeError)
      end
    end

    describe 'method not found handling' do
      it 'raises NoMethodError when method does not exist on target utility' do
        expect { HudUtilityCurrent.nonexistent_method }.to raise_error(NoMethodError)
      end
    end
  end
end
