###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/enrollment_rollup_context'

RSpec.describe ClientHistory::Calculator, type: :model do
  include_context 'enrollment rollup context'

  let(:enrollments) { destination_client.service_history_enrollments.entry.includes(:enrollment).order(first_date_in_program: :desc).to_a }
  let(:calculator) { described_class.new(client: destination_client, enrollments: enrollments) }
  let(:shelter_a_she) { enrollments.detect { |e| e.project_id == shelter_a.ProjectID } }
  let(:shelter_b_she) { enrollments.detect { |e| e.project_id == shelter_b.ProjectID } }
  let(:housing_she) { enrollments.detect { |e| e.project_id == housing.ProjectID } }

  describe '#dates_served' do
    it 'returns each night of an exited stay, excluding the exit date' do
      expect(calculator.dates_served(shelter_a_she)).to eq((Date.new(2021, 1, 1)..Date.new(2021, 1, 10)).to_a)
    end
  end

  describe '#most_recent_service_date' do
    it 'returns the last night served' do
      expect(calculator.most_recent_service_date(housing_she)).to eq(Date.new(2021, 1, 31))
    end
  end

  describe '#residential_dates' do
    it 'returns only housed nights from permanent housing, starting at move-in' do
      expect(calculator.residential_dates).to match_array((Date.new(2021, 1, 19)..Date.new(2021, 1, 31)).to_a)
    end
  end

  describe '#new_episode?' do
    it 'is true for a shelter entry with no homeless nights in the prior 30 days' do
      expect(calculator.new_episode?(enrollment: shelter_a_she)).to eq(true)
    end

    it 'is false for a shelter entry preceded by homeless nights within 30 days' do
      expect(calculator.new_episode?(enrollment: shelter_b_she)).to eq(false)
    end

    it 'is false for permanent housing regardless of history' do
      expect(calculator.new_episode?(enrollment: housing_she)).to eq(false)
    end

    # The shared fixture's last homeless night is 2021-01-19 (Shelter B, exited 01-20);
    # Housing is occupied 01-19..01-31 after its 01-18 move-in.
    def new_episode_for_entry(destination, entry_date)
      rebuild_service_history!
      entries = destination.service_history_enrollments.entry.to_a
      described_class.new(client: destination, enrollments: entries).
        new_episode?(enrollment: entries.detect { |e| e.entry_date == entry_date })
    end

    def build_episode_client
      destination = create :hud_client, data_source_id: warehouse_data_source.id, FirstName: 'Gap', LastName: 'Client'
      source = create_linked_source_client(destination, first_name: 'Gap', last_name: 'Source')
      [destination, source]
    end

    context 'housed nights in permanent housing' do
      it 'is true when the gap holds seven consecutive nights housed after move-in' do
        create_enrollment(source_client, shelter_a, entry: '2021-01-27', exit_date: '2021-01-29')
        expect(new_episode_for_entry(destination_client, Date.new(2021, 1, 27))).to eq(true)
      end

      it 'is false when the gap holds only six housed nights' do
        create_enrollment(source_client, shelter_a, entry: '2021-01-26', exit_date: '2021-01-28')
        expect(new_episode_for_entry(destination_client, Date.new(2021, 1, 26))).to eq(false)
      end
    end

    context 'nights in transitional housing' do
      let!(:transitional) { create_project('Transitional', project_type: HudHelper.util.residential_project_type_numbers_by_code[:th].first) }
      let(:episode_client) { build_episode_client }
      let(:destination) { episode_client.first }
      let(:source) { episode_client.last }

      before do
        create_enrollment(source, shelter_a, entry: '2020-01-01', exit_date: '2020-01-10')
        create_enrollment(source, transitional, entry: '2020-01-10', exit_date: '2020-01-31')
      end

      it 'is true when seven consecutive TH nights separate two shelter stays' do
        create_enrollment(source, shelter_a, entry: '2020-01-17', exit_date: '2020-01-19')
        expect(new_episode_for_entry(destination, Date.new(2020, 1, 17))).to eq(true)
      end

      it 'is false when only six TH nights separate two shelter stays' do
        create_enrollment(source, shelter_a, entry: '2020-01-16', exit_date: '2020-01-18')
        expect(new_episode_for_entry(destination, Date.new(2020, 1, 16))).to eq(false)
      end
    end

    context 'presumed permanent housing between stays' do
      let(:episode_client) { build_episode_client }
      let(:destination) { episode_client.first }
      let(:source) { episode_client.last }
      let(:permanent_destination) { HudHelper.util.permanent_destinations.first }
      let(:temporary_destination) { HudHelper.util.temporary_destinations.first }
      let(:permanent_prior_situation) { HudHelper.util.permanent_situations(as: :prior).first }

      it 'is true seven nights after a shelter exit to a permanent destination' do
        create_enrollment(source, shelter_a, entry: '2020-01-01', exit_date: '2020-01-10', destination: permanent_destination)
        create_enrollment(source, shelter_a, entry: '2020-01-17', exit_date: '2020-01-19')
        expect(new_episode_for_entry(destination, Date.new(2020, 1, 17))).to eq(true)
      end

      it 'is false six nights after a shelter exit to a permanent destination' do
        create_enrollment(source, shelter_a, entry: '2020-01-01', exit_date: '2020-01-10', destination: permanent_destination)
        create_enrollment(source, shelter_a, entry: '2020-01-16', exit_date: '2020-01-18')
        expect(new_episode_for_entry(destination, Date.new(2020, 1, 16))).to eq(false)
      end

      it 'is false seven nights after a shelter exit to a temporary destination' do
        create_enrollment(source, shelter_a, entry: '2020-01-01', exit_date: '2020-01-10', destination: temporary_destination)
        create_enrollment(source, shelter_a, entry: '2020-01-17', exit_date: '2020-01-19')
        expect(new_episode_for_entry(destination, Date.new(2020, 1, 17))).to eq(false)
      end

      it 'is true when the new entry reports a permanent prior living situation across a seven-night gap' do
        create_enrollment(source, shelter_a, entry: '2020-01-01', exit_date: '2020-01-10', destination: nil)
        create_enrollment(source, shelter_a, entry: '2020-01-17', exit_date: '2020-01-19', LivingSituation: permanent_prior_situation)
        expect(new_episode_for_entry(destination, Date.new(2020, 1, 17))).to eq(true)
      end
    end

    context 'gaps with no recorded nights' do
      let(:episode_client) { build_episode_client }
      let(:destination) { episode_client.first }
      let(:source) { episode_client.last }

      before { create_enrollment(source, shelter_a, entry: '2020-01-01', exit_date: '2020-01-10', destination: nil) }

      it 'is true when ninety nights pass with nothing recorded' do
        create_enrollment(source, shelter_a, entry: '2020-04-09', exit_date: '2020-04-11')
        expect(new_episode_for_entry(destination, Date.new(2020, 4, 9))).to eq(true)
      end

      it 'is false when eighty-nine nights pass with nothing recorded' do
        create_enrollment(source, shelter_a, entry: '2020-04-08', exit_date: '2020-04-10')
        expect(new_episode_for_entry(destination, Date.new(2020, 4, 8))).to eq(false)
      end
    end

    context 'permanent housing nights before move-in' do
      let(:episode_client) { build_episode_client }
      let(:destination) { episode_client.first }
      let(:source) { episode_client.last }
      let(:homeless_prior_situation) { HudHelper.util.homeless_situations(as: :prior).first }

      before { create_enrollment(source, shelter_a, entry: '2020-01-01', exit_date: '2020-01-10', destination: nil) }

      it 'keeps the episode open when the client entered PH from a homeless situation and never moved in' do
        create_enrollment(source, housing, entry: '2020-02-01', exit_date: '2020-02-15', LivingSituation: homeless_prior_situation)
        create_enrollment(source, shelter_a, entry: '2020-05-01', exit_date: '2020-05-03')
        expect(new_episode_for_entry(destination, Date.new(2020, 5, 1))).to eq(false)
      end

      it 'ignores PH nights before move-in when the prior living situation is not recorded' do
        create_enrollment(source, housing, entry: '2020-02-01', exit_date: '2020-02-15')
        create_enrollment(source, shelter_a, entry: '2020-05-01', exit_date: '2020-05-03')
        expect(new_episode_for_entry(destination, Date.new(2020, 5, 1))).to eq(true)
      end
    end

    context 'two records of the same stay' do
      let(:episode_client) { build_episode_client }
      let(:destination) { episode_client.first }
      let(:source) { episode_client.last }

      it 'marks only the earliest-built record as the new episode' do
        create_enrollment(source, shelter_a, entry: '2020-01-01', exit_date: '2020-01-10')
        create_enrollment(source, shelter_a, entry: '2020-01-01', exit_date: '2020-01-10')
        rebuild_service_history!
        entries = destination.service_history_enrollments.entry.order(:id).to_a
        calculator = described_class.new(client: destination, enrollments: entries)

        expect(entries.map { |e| calculator.new_episode?(enrollment: e) }).to eq([true, false])
      end
    end
  end

  describe 'query behaviour' do
    it 'loads service rows once for any number of readers' do
      calculator
      queries = count_database_queries do
        enrollments.each { |e| calculator.dates_served(e) }
        enrollments.each { |e| calculator.most_recent_service_date(e) }
        enrollments.each { |e| calculator.new_episode?(enrollment: e) }
        calculator.residential_dates
      end
      expect(queries).to eq(1)
    end
  end
end
