# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'
require_relative '../../support/submit_form_spec_helpers'
require_relative '../../support/shared_examples/submit_form'

RSpec.describe 'SubmitForm for Project', type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  before(:each) { hmis_login(user) }

  let(:definition) { Hmis::Form::Definition.find_by(role: :PROJECT) }
  let(:hud_values) do
    {
      'projectName' => 'Test Project',
      'description' => 'project description',
      'contactInformation' => 'contact info',
      'operatingStartDate' => '2023-01-13',
      'operatingEndDate' => nil,
      'projectType' => 'ES_NBN',
      'residentialAffiliation' => 'NO',
      'housingType' => 'SITE_BASED_SINGLE_SITE',
      'targetPopulation' => 'HIV_PERSONS_WITH_HIV_AIDS',
      'HOPWAMedAssistedLivingFac' => 'NO',
      'continuumProject' => 'NO',
    }.stringify_keys
  end
  let(:input) do
    {
      form_definition_id: definition.id,
      hud_values: hud_values,
      values: hud_values_to_values_by_link_id(hud_values),
      organization_id: o1.id,
      confirmed: false,
    }
  end

  it_behaves_like 'submit form updates user correctly'

  it 'creates a new project' do
    project = nil
    expect do
      record, = submit_form(input)
      project = Hmis::Hud::Project.find(record['id'])
    end.to change(Hmis::Hud::Project, :count).by(1)
    expect(project.project_name).to eq('Test Project')
    expect(project.description).to eq('project description')
    expect(project.operating_start_date).to eq(Date.parse('2023-01-13'))
    expect(project.operating_end_date).to be nil
    expect(project.project_type).to eq(1) # ES_NBN
  end

  it 'persists submitted form values to an existing project' do
    expect do
      submit_form(input.merge(record_id: p1.id))
      p1.reload
    end.to change(p1, :project_name).to('Test Project')
  end

  context 'when user lacks can_edit_project_details permission' do
    before { remove_permissions(access_control, :can_edit_project_details) }

    it 'returns access denied' do
      expect_gql_error submit_form(input, expect_raise: true), message: /not authorized/
    end
  end

  describe 'project operating end date' do
    let!(:project) { create :hmis_hud_project, data_source: ds1, organization: o1, with_coc: true, operating_end_date: nil }

    let(:today) { Date.current }
    let(:end_date) { today }
    let(:hud_values) { super().merge(operatingEndDate: end_date.strftime('%Y-%m-%d')).stringify_keys }
    let(:input) { super().merge(record_id: project.id) }

    context 'with open enrollments' do
      let!(:enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: project, entry_date: 1.month.ago }
      let!(:exited_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: project, entry_date: 1.month.ago, exit_date: 2.days.ago }

      it 'should warn if changing the end date for a project with open enrollments' do
        record, errors = submit_form(input, expect_validation_errors: true)
        expect(record).to be_nil
        expect(project.reload.operating_end_date).to be_nil # didn't update
        expect(errors).to contain_exactly(include('severity' => 'warning', 'type' => 'information', 'fullMessage' => Hmis::Hud::Validators::ProjectValidator.open_enrollments_message(1)))
      end

      it 'should not warn about enrollments that exited today' do
        # exit the enrollment today
        create(:hmis_hud_exit, enrollment: enrollment, client: enrollment.client, data_source: ds1, exit_date: today)

        record, = submit_form(input)
        expect(record).to be_present
        expect(project.reload.operating_end_date).to be_present
      end
    end

    context 'with open funders and inventory' do
      let!(:funder) { create :hmis_hud_funder, data_source: ds1, project: project, user: u1, end_date: nil }
      let!(:coc) { create :hmis_hud_project_coc, data_source: ds1, project: project, coc_code: 'CO-500', user: u1 }
      let!(:inventory) { create :hmis_hud_inventory, data_source: ds1, project: project, coc_code: coc.coc_code, inventory_start_date: '2020-01-01', inventory_end_date: nil, user: u1 }

      let(:hud_values) { super().merge(operatingEndDate: today.strftime('%Y-%m-%d')).stringify_keys }
      let(:input) { super().merge(record_id: project.id) }

      it 'should warn if closing project' do
        record, errors = submit_form(input, expect_validation_errors: true)
        expect(record).to be_nil
        expect(project.reload.operating_end_date).to be nil # unchanged
        expect(errors).to contain_exactly(
          a_hash_including('severity' => 'warning', 'type' => 'information', 'fullMessage' => Hmis::Hud::Validators::ProjectValidator.open_funders_message(1)),
          a_hash_including('severity' => 'warning', 'type' => 'information', 'fullMessage' => Hmis::Hud::Validators::ProjectValidator.open_inventory_message(1)),
        )
        expect(inventory.reload.inventory_end_date).to be nil
        expect(funder.reload.end_date).to be nil
      end

      context 'when confirmed' do
        let(:hud_values) { super().merge(operatingEndDate: today.strftime('%Y-%m-%d')).stringify_keys }
        let(:input) { super().merge(record_id: project.id, confirmed: true) }

        it 'should close related funders and inventory if confirmed' do
          submit_form(input)
          expect(project.reload.operating_end_date).to be_present
          expect(inventory.reload.inventory_end_date).to be_present
          expect(funder.reload.end_date).to be_present
        end
      end

      context 'when operating end date is not changed' do
        let!(:project) { create :hmis_hud_project, data_source: ds1, organization: o1, with_coc: true, operating_end_date: '2030-01-01' }
        let(:hud_values) { super().merge(operatingEndDate: '2030-01-01').stringify_keys }
        let(:input) { super().merge(record_id: project.id) }

        it 'should NOT warn if the operating end date was not changed' do
          submit_form(input)
          expect(project.reload.operating_end_date).to eq(Date.parse('2030-01-01'))
          expect(inventory.reload.inventory_end_date).to be nil
          expect(funder.reload.end_date).to be nil
        end
      end

      context 'when operating end date is cleared' do
        let!(:project) { create :hmis_hud_project, data_source: ds1, organization: o1, with_coc: true, operating_end_date: '2030-01-01' }
        let(:hud_values) { super().merge(operatingEndDate: nil).stringify_keys }
        let(:input) { super().merge(record_id: project.id) }

        it 'should NOT warn if the operating end date was cleared' do
          submit_form(input)
          expect(project.reload.operating_end_date).to be nil
          expect(inventory.reload.inventory_end_date).to be nil
          expect(funder.reload.end_date).to be nil
        end
      end
    end
  end

  describe 'initial related records' do
    context 'when initial CoC code is provided' do
      let(:hud_values) { super().merge('initialCocCode' => 'MA-504', 'initialGeocode' => '250354').stringify_keys }

      it 'creates a new project CoC record' do
        record, = submit_form(input)
        project = Hmis::Hud::Project.find(record['id'])
        expect(project.project_cocs.count).to eq(1)
        expect(project.project_cocs.first.coc_code).to eq('MA-504')
        expect(project.project_cocs.first.geocode).to eq('250354')
      end
    end

    context 'when initial funder is provided' do
      let(:hud_values) { super().merge(initialFunder: 'LOCAL_OR_OTHER_FUNDING_SOURCE', initialOtherFunder: 'Xyz Funder', initialFunderGrantId: '12345').stringify_keys }

      it 'creates a new funder record' do
        record, = submit_form(input)
        project = Hmis::Hud::Project.find(record['id'])
        expect(project.funders.count).to eq(1)
        expect(project.funders.first.funder).to eq(46) # Local or other funding source
        expect(project.funders.first.other_funder).to eq('Xyz Funder')
        expect(project.funders.first.grant_id).to eq('12345')
        expect(project.funders.first.start_date).to eq(project.operating_start_date)
      end
    end

    context 'when initial HMIS participation type is provided' do
      let(:hud_values) { super().merge(initialHmisParticipationType: 'HMIS_PARTICIPATING').stringify_keys }

      it 'creates a new HMIS participation record' do
        record, = submit_form(input)
        project = Hmis::Hud::Project.find(record['id'])
        expect(project.hmis_participations.count).to eq(1)
        expect(project.hmis_participations.first.hmis_participation_type).to eq(1)
        expect(project.hmis_participations.first.hmis_participation_status_start_date).to eq(project.operating_start_date)
      end
    end

    context 'when initial CE participation is provided' do
      let(:hud_values) { super().merge(initialCeAccessPoint: 'YES', initialCeParticipationServices: ['PREVENTION_ASSESSMENT', 'HOUSING_ASSESSMENT'], initialCeReceivesReferrals: 'YES').stringify_keys }

      it 'creates a new CE participation record' do
        record, = submit_form(input)
        project = Hmis::Hud::Project.find(record['id'])
        expect(project.ce_participations.count).to eq(1)
        expect(project.ce_participations.first.access_point).to eq(1)
        expect(project.ce_participations.first.prevention_assessment).to eq(1)
        expect(project.ce_participations.first.crisis_assessment).to eq(0)
        expect(project.ce_participations.first.housing_assessment).to eq(1)
        expect(project.ce_participations.first.direct_services).to eq(0)
        expect(project.ce_participations.first.receives_referrals).to eq(1)
        expect(project.ce_participations.first.ce_participation_status_start_date).to eq(project.operating_start_date)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
  c.include SubmitFormSpecHelpers
end
