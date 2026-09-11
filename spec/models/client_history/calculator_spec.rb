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

  let(:enrollments) { destination_client.service_history_enrollments.entry.order(first_date_in_program: :desc).to_a }
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

    # The fixture's last homeless night is 2021-01-19 (Shelter B, exited 01-20).
    def new_episode_for_shelter_entry_on(entry)
      create_enrollment(source_client, shelter_a, entry: entry.to_s, exit_date: (entry + 2.days).to_s)
      rebuild_service_history!
      entries = destination_client.service_history_enrollments.entry.to_a
      described_class.new(client: destination_client, enrollments: entries).
        new_episode?(enrollment: entries.detect { |e| e.entry_date == entry })
    end

    it 'is false when the last homeless night is exactly 30 days before entry' do
      expect(new_episode_for_shelter_entry_on(Date.new(2021, 2, 18))).to eq(false)
    end

    it 'is true when the last homeless night is 31 days before entry' do
      expect(new_episode_for_shelter_entry_on(Date.new(2021, 2, 19))).to eq(true)
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
