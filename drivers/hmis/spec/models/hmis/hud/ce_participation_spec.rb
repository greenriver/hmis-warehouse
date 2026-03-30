###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Hud::CeParticipation, type: :model do
  let(:ref_date) { Date.new(2025, 6, 15) }

  describe '.active_on_date' do
    it 'includes records with no end date when the start is on or before the date' do
      rec = create(
        :hmis_hud_ce_participation,
        CEParticipationStatusStartDate: Date.new(2020, 1, 1),
        CEParticipationStatusEndDate: nil,
      )
      expect(described_class.active_on_date(ref_date)).to include(rec)
    end

    it 'includes records when the date falls between start and end (inclusive)' do
      rec = create(
        :hmis_hud_ce_participation,
        CEParticipationStatusStartDate: Date.new(2025, 6, 1),
        CEParticipationStatusEndDate: Date.new(2025, 6, 30),
      )
      expect(described_class.active_on_date(ref_date)).to include(rec)
    end

    it 'includes records when the date equals the end date' do
      rec = create(
        :hmis_hud_ce_participation,
        CEParticipationStatusStartDate: Date.new(2025, 1, 1),
        CEParticipationStatusEndDate: ref_date,
      )
      expect(described_class.active_on_date(ref_date)).to include(rec)
    end

    it 'excludes records when the status ended before the date' do
      rec = create(
        :hmis_hud_ce_participation,
        CEParticipationStatusStartDate: Date.new(2020, 1, 1),
        CEParticipationStatusEndDate: Date.new(2025, 6, 1),
      )
      expect(described_class.active_on_date(ref_date)).not_to include(rec)
    end

    it 'excludes records when the status has not started yet' do
      rec = create(
        :hmis_hud_ce_participation,
        CEParticipationStatusStartDate: Date.new(2025, 7, 1),
        CEParticipationStatusEndDate: nil,
      )
      expect(described_class.active_on_date(ref_date)).not_to include(rec)
    end
  end

  describe '.access_point' do
    it 'includes only AccessPoint = 1' do
      yes = create(:hmis_hud_ce_participation, AccessPoint: 1)
      no = create(:hmis_hud_ce_participation, AccessPoint: 0)

      expect(described_class.access_point).to include(yes)
      expect(described_class.access_point).not_to include(no)
    end
  end
end
