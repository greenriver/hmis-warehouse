###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudPit::CellsController, type: :request do
  let(:user) { create(:user) }
  let(:report) do
    create(
      :hud_reports_report_instance,
      user: user,
      report_name: 'Point in Time Count - FY 2025',
      options: { 'report_version' => 'fy2025' },
    )
  end

  before do
    user.legacy_roles << create(:role, can_view_own_hud_reports: true, can_view_hiv_status: true)
    sign_in(user)
  end

  describe 'GET #show — Additional Homeless Populations HIV/AIDS row (B4)' do
    let(:cell_path) do
      hud_reports_pit_question_cell_path(
        pit_id: report.id,
        question_id: 'Additional Homeless Populations',
        id: 'B4',
        table: 'Additional Homeless Populations',
      )
    end

    context 'user WITH can_view_hiv_status' do
      it 'allows access' do
        get cell_path
        expect(response).to be_successful
      end
    end

    context 'user WITHOUT can_view_hiv_status' do
      before do
        user.legacy_roles.destroy_all
        user.legacy_roles << create(:role, can_view_own_hud_reports: true, can_view_hiv_status: false)
      end

      it 'redirects with an alert' do
        get cell_path
        expect(response).to redirect_to(
          result_hud_reports_pit_question_path(pit_id: report.id, id: 'Additional Homeless Populations'),
        )
        expect(flash[:alert]).to eq('You do not have permission to view HIV/AIDS drilldown data.')
      end
    end
  end

  describe 'row_number_from_cell_label' do
    subject(:row_number) do
      HudPit::CellsController.allocate.send(:row_number_from_cell_label, cell_label)
    end

    let(:cell_label) { 'B4' }

    it 'parses column-letter + row labels produced by hud_reports/_table.haml' do
      expect(row_number).to eq(4)
    end

    context 'when the label uses another column on the same row' do
      let(:cell_label) { 'A4' }

      it 'still resolves the row number (column letter is not used here)' do
        expect(row_number).to eq(4)
      end
    end

    context 'when the row has multiple digits' do
      let(:cell_label) { 'C12' }

      it 'uses the first contiguous digit run as the row' do
        expect(row_number).to eq(12)
      end
    end

    it 'keeps FY2025 HIV/AIDS row aligned with B{row}-style drilldown ids' do
      row = HudPit::Generators::Pit::Fy2025::AdditionalHomelessPopulations::HIV_AIDS_ROW
      label = "B#{row}"
      parsed = HudPit::CellsController.allocate.send(:row_number_from_cell_label, label)
      expect(parsed).to eq(row)
    end
  end

  describe 'GET #show — Additional Homeless Populations non-HIV row (B2, Mental Illness)' do
    let(:cell_path) do
      hud_reports_pit_question_cell_path(
        pit_id: report.id,
        question_id: 'Additional Homeless Populations',
        id: 'B2',
        table: 'Additional Homeless Populations',
      )
    end

    context 'user WITHOUT can_view_hiv_status' do
      before do
        user.legacy_roles.destroy_all
        user.legacy_roles << create(:role, can_view_own_hud_reports: true, can_view_hiv_status: false)
      end

      it 'allows access' do
        get cell_path
        expect(response).to be_successful
      end
    end
  end
end
