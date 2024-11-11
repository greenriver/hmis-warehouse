require 'rails_helper'

require_relative 'hopwa_caper_shared_context'
RSpec.describe 'HOPWA CAPER PHP', type: :model do
  include_context('HOPWA CAPER shared context')

  let(:funder) do
    HudUtility2024.funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing Placement')
  end

  let(:project) do
    create_hopwa_project(funder: funder)
  end

  context 'With one multi-member household served with rental assistance' do
    let!(:household) do
      create_hopwa_eligible_household(
        project: project,
        other_clients: [create(:hud_client, data_source: data_source)],
      )
    end

    it 'reports household count' do
      report = create_report([project])
      run_report(report)
      rows = question_as_rows(question_number: 'Q4', report: report).to_h
      expect(rows.fetch('How many households were served with PHP assistance?')).to eq(1)
    end
  end
end
