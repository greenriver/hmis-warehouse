###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https: //github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CasClientData do
  let(:client) { create(:grda_warehouse_hud_client) }
  let(:project_type_codes) { [13] } # RRH project type

  describe '#enrolled_in_rrh_pre_move_in' do
    let(:ongoing_enrollments) do
      [
        OpenStruct.new(
          project_type: project_type,
          move_in_date: move_in_date,
          rrh_sub_type: rrh_sub_type,
        ),
      ]
    end

    context 'when ongoing_enrollments is nil' do
      let(:ongoing_enrollments) { nil }
      let(:project_type) { nil }
      let(:move_in_date) { nil }
      let(:rrh_sub_type) { nil }

      it 'returns false' do
        expect(client.enrolled_in_rrh_pre_move_in(ongoing_enrollments)).to be false
      end
    end

    context 'when client is enrolled in RRH' do
      let(:project_type) { 13 }

      context 'with no move-in date and not services-only' do
        let(:move_in_date) { nil }
        let(:rrh_sub_type) { 2 }

        it 'returns true' do
          expect(client.enrolled_in_rrh_pre_move_in(ongoing_enrollments)).to be true
        end
      end

      context 'with no move-in date but services-only' do
        let(:move_in_date) { nil }
        let(:rrh_sub_type) { 1 }

        it 'returns false' do
          expect(client.enrolled_in_rrh_pre_move_in(ongoing_enrollments)).to be false
        end
      end

      context 'with move-in date and not services-only' do
        let(:move_in_date) { Date.current }
        let(:rrh_sub_type) { 2 }

        it 'returns false' do
          expect(client.enrolled_in_rrh_pre_move_in(ongoing_enrollments)).to be false
        end
      end

      context 'with move-in date and services-only' do
        let(:move_in_date) { Date.current }
        let(:rrh_sub_type) { 1 }

        it 'returns false' do
          expect(client.enrolled_in_rrh_pre_move_in(ongoing_enrollments)).to be false
        end
      end
    end

    context 'when client is not enrolled in RRH' do
      let(:project_type) { 3 } # PSH project type
      let(:move_in_date) { nil }
      let(:rrh_sub_type) { nil }

      it 'returns false' do
        expect(client.enrolled_in_rrh_pre_move_in(ongoing_enrollments)).to be false
      end
    end
  end
end
