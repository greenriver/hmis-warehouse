# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::EnrollmentEligibilityScope, type: :model do
  let!(:destination_data_source) { create(:destination_data_source) }
  let!(:hmis_data_source) { create(:hmis_data_source) }
  let(:current_date) { Date.new(2024, 12, 26) }
  let(:configuration) { instance_double(Hmis::Ce::Configuration) }
  let(:scope) { described_class.new(current_date: current_date, configuration: configuration) }

  let(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: hmis_data_source) }
  let(:destination_client) { client.destination_client }
  let(:clients) { GrdaWarehouse::Hud::Client.where(id: destination_client.id) }

  let!(:project_in_group) { create(:hmis_hud_project, data_source: hmis_data_source) }
  let!(:project_out_of_group) { create(:hmis_hud_project, data_source: hmis_data_source) }

  before do
    allow(configuration).to receive(:eligibility_lookback_months).and_return(0)
    allow(configuration).to receive(:eligibility_project_group).and_return(nil)
  end

  describe '#call' do
    it 'returns no enrollments when no clients are provided' do
      expect(scope.call([]).to_a).to eq([])
    end

    context 'with lookback months 0' do
      let!(:open_enrollment) do
        create(
          :hmis_hud_enrollment,
          data_source: hmis_data_source,
          client: client,
          project: project_in_group,
          EntryDate: current_date - 1.month,
        )
      end
      let!(:exited_enrollment) do
        create(
          :hmis_hud_enrollment,
          data_source: hmis_data_source,
          client: client,
          project: project_in_group,
          EntryDate: current_date - 3.months,
          exit_date: current_date - 1.month,
        )
      end

      it 'includes open enrollments and excludes exited enrollments' do
        expect(scope.call(clients)).to contain_exactly(open_enrollment)
      end
    end

    context 'with lookback months > 0' do
      before do
        allow(configuration).to receive(:eligibility_lookback_months).and_return(2)
      end

      let!(:open_enrollment) do
        create(
          :hmis_hud_enrollment,
          data_source: hmis_data_source,
          client: client,
          project: project_in_group,
          EntryDate: current_date - 1.month,
        )
      end
      let!(:recently_exited_enrollment) do
        create(
          :hmis_hud_enrollment,
          data_source: hmis_data_source,
          client: client,
          project: project_in_group,
          EntryDate: current_date - 3.months,
          exit_date: current_date - 1.month,
        )
      end
      let!(:old_exited_enrollment) do
        create(
          :hmis_hud_enrollment,
          data_source: hmis_data_source,
          client: client,
          project: project_in_group,
          EntryDate: current_date - 6.months,
          exit_date: current_date - 4.months,
        )
      end

      it 'includes enrollments overlapping the lookback window' do
        expect(scope.call(clients)).to contain_exactly(open_enrollment, recently_exited_enrollment)
      end
    end

    context 'with a configured project group' do
      let!(:project_group) do
        create(:hmis_project_group, data_source: hmis_data_source, with_projects: [project_in_group])
      end
      let!(:in_group_enrollment) do
        create(
          :hmis_hud_enrollment,
          data_source: hmis_data_source,
          client: client,
          project: project_in_group,
          EntryDate: current_date - 1.month,
        )
      end
      let!(:out_of_group_enrollment) do
        create(
          :hmis_hud_enrollment,
          data_source: hmis_data_source,
          client: client,
          project: project_out_of_group,
          EntryDate: current_date - 1.month,
        )
      end

      before do
        allow(configuration).to receive(:eligibility_project_group).and_return(project_group)
      end

      it 'limits enrollments to projects in the group' do
        expect(scope.call(clients)).to contain_exactly(in_group_enrollment)
      end
    end

    context 'with a configured empty project group' do
      let!(:empty_project_group) { create(:hmis_project_group, data_source: hmis_data_source) }
      let!(:open_enrollment) do
        create(
          :hmis_hud_enrollment,
          data_source: hmis_data_source,
          client: client,
          project: project_in_group,
          EntryDate: current_date - 1.month,
        )
      end

      before do
        allow(configuration).to receive(:eligibility_project_group).and_return(empty_project_group)
      end

      it 'returns no enrollments' do
        expect(scope.call(clients)).to be_empty
        expect(open_enrollment).to be_present
      end
    end
  end
end
