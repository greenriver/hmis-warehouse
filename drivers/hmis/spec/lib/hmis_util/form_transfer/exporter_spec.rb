###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisUtil::FormTransfer::Exporter do
  let(:data_source) { create(:hmis_data_source) }
  let(:other_data_source) { create(:hmis_data_source) }
  let(:output) { StringIO.new }

  def form_json(*items)
    { 'item' => [{ 'type' => 'GROUP', 'link_id' => 'group', 'item' => items }] }
  end

  def string_item(link_id, custom_field_key: nil)
    item = { 'type' => 'STRING', 'link_id' => link_id, 'text' => link_id.humanize }
    item['mapping'] = { 'custom_field_key' => custom_field_key } if custom_field_key
    item
  end

  def export(**options)
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'export.json')
      described_class.new(data_source_id: data_source.id, output: output, **options).write(path)
      JSON.parse(File.read(path))
    end
  end

  describe 'form definitions' do
    let!(:retired) { create(:hmis_form_definition, data_source: data_source, identifier: 'intake_extra', role: 'CUSTOM_ASSESSMENT', version: 1, status: 'retired') }
    let!(:published) { create(:hmis_form_definition, data_source: data_source, identifier: 'intake_extra', role: 'CUSTOM_ASSESSMENT', version: 2, status: 'published') }
    let!(:unselected) { create(:hmis_form_definition, data_source: data_source, identifier: 'other_form', role: 'CUSTOM_ASSESSMENT') }
    let!(:other_data_source_form) { create(:hmis_form_definition, data_source: other_data_source, identifier: 'intake_extra', role: 'CUSTOM_ASSESSMENT', version: 3) }

    it 'exports every version of the selected identifiers from its own data source only' do
      payload = export(identifiers: ['intake_extra'])

      expect(payload['definitions'].map { |d| [d['identifier'], d['version'], d['status']] }).to eq(
        [['intake_extra', 1, 'retired'], ['intake_extra', 2, 'published']],
      )
    end

    it 'filters by role' do
      service_form = create(:hmis_form_definition, data_source: data_source, role: 'SERVICE')

      payload = export(roles: ['SERVICE'])

      expect(payload['definitions'].map { |d| d['identifier'] }).to contain_exactly(service_form.identifier)
    end

    it 'raises when nothing matches' do
      expect { export(identifiers: ['missing']) }.to raise_error(RuntimeError, 'No form definitions matched')
    end
  end

  describe 'custom data element definitions' do
    let!(:definition) do
      create(
        :hmis_form_definition,
        data_source: data_source,
        identifier: 'pets',
        role: 'CUSTOM_ASSESSMENT',
        definition: form_json(string_item('pet_name', custom_field_key: 'pet_name'), string_item('pet_age', custom_field_key: 'pet_age_missing')),
      )
    end
    let!(:linked_by_identifier) do
      create(:hmis_custom_data_element_definition, data_source: data_source, owner_type: 'Hmis::Hud::CustomAssessment', key: 'pet_notes', form_definition_identifier: 'pets')
    end
    let!(:linked_by_mapping_only) do
      create(:hmis_custom_data_element_definition, data_source: data_source, owner_type: 'Hmis::Hud::CustomAssessment', key: 'pet_name', form_definition_identifier: nil)
    end
    let!(:unrelated) do
      create(:hmis_custom_data_element_definition, data_source: data_source, owner_type: 'Hmis::Hud::CustomAssessment', key: 'unrelated')
    end

    it 'includes CDEDs linked by identifier and CDEDs found only through a field mapping' do
      payload = export(identifiers: ['pets'])

      expect(payload['custom_data_element_definitions'].map { |c| c['key'] }).to contain_exactly('pet_notes', 'pet_name')
    end

    it 'warns about a mapping with no matching CDED' do
      payload = export(identifiers: ['pets'])

      expect(payload['warnings']).to contain_exactly(
        'pets v1 item pet_age maps to missing CDED Hmis::Hud::CustomAssessment/pet_age_missing',
      )
    end
  end

  describe 'form rules and the projects they reference' do
    let!(:definition) { create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT') }
    let!(:organization) { create(:hmis_hud_organization, data_source: data_source) }
    let!(:org_project_a) { create(:hmis_hud_project, data_source: data_source, organization: organization) }
    let!(:org_project_b) { create(:hmis_hud_project, data_source: data_source, organization: organization) }
    let!(:rule_project) { create(:hmis_hud_project, data_source: data_source) }
    let!(:unreferenced_project) { create(:hmis_hud_project, data_source: data_source) }
    let!(:funder) { create(:hmis_hud_funder, data_source: data_source, project: rule_project, DateCreated: Time.zone.parse('2024-03-05 10:11:12')) }

    before do
      create(:hmis_form_instance, data_source: data_source, definition: definition, entity: rule_project)
      create(:hmis_form_instance, data_source: data_source, definition: definition, entity: organization)
      create(:hmis_form_instance, data_source: data_source, definition: definition, entity: nil, project_type: 1)
      create(:hmis_form_instance, data_source: data_source, definition: definition, entity: unreferenced_project, active: false)
    end

    it 'exports active rules, pointing at projects and organizations by HUD ID' do
      rules = export(identifiers: ['pets'])['form_rules']

      expect(rules.map { |r| r.slice('entity_type', 'project_hud_id', 'organization_hud_id', 'project_type') }).to contain_exactly(
        { 'entity_type' => 'Hmis::Hud::Project', 'project_hud_id' => rule_project.ProjectID, 'organization_hud_id' => nil, 'project_type' => nil },
        { 'entity_type' => 'Hmis::Hud::Organization', 'project_hud_id' => nil, 'organization_hud_id' => organization.OrganizationID, 'project_type' => nil },
        { 'entity_type' => nil, 'project_hud_id' => nil, 'organization_hud_id' => nil, 'project_type' => 1 },
      )
    end

    it "exports the rule's project and every project in a rule's organization, but no others" do
      payload = export(identifiers: ['pets'])

      expect(payload['projects'].map { |p| p['ProjectID'] }).to contain_exactly(rule_project.ProjectID, org_project_a.ProjectID, org_project_b.ProjectID)
      expect(payload['organizations'].map { |o| o['OrganizationID'] }).to contain_exactly(organization.OrganizationID, rule_project.organization.OrganizationID)
    end

    it "exports each project's funders with ISO 8601 timestamps that keep seconds" do
      payload = export(identifiers: ['pets'])
      exported = payload['projects'].find { |p| p['ProjectID'] == rule_project.ProjectID }

      expect(exported['funders'].map { |f| [f['FunderID'], Time.zone.parse(f['DateCreated'])] }).to eq(
        [[funder.FunderID, Time.zone.parse('2024-03-05 10:11:12')]],
      )
    end

    it 'leaves out a project whose organization is deleted, and warns' do
      # update_columns, because destroy! would also delete the organization's projects
      rule_project.organization.update_columns(DateDeleted: Time.current)

      payload = export(identifiers: ['pets'])

      expect(payload['projects'].map { |p| p['ProjectID'] }).to contain_exactly(org_project_a.ProjectID, org_project_b.ProjectID)
      expect(payload['warnings']).to include("project #{rule_project.ProjectID} belongs to a missing or deleted organization")
    end

    it 'skips projects when include_projects is false' do
      payload = export(identifiers: ['pets'], include_projects: false)

      expect([payload['projects'], payload['organizations']]).to eq([[], []])
    end
  end

  describe 'project configs' do
    let!(:definition) { create(:hmis_form_definition, data_source: data_source, role: 'CUSTOM_ASSESSMENT') }
    let!(:sender) { create(:hmis_hud_project, data_source: data_source) }
    let!(:receiver) { create(:hmis_hud_project, data_source: data_source) }

    before do
      create(:hmis_project_ce_config, data_source: data_source, project: receiver, receives_direct_referrals: true, receives_direct_referrals_from: [sender.id])
    end

    it 'writes receives_direct_referrals_from as HUD IDs and exports the projects it names' do
      payload = export(include_ce: false)

      expect(payload['project_configs'].map { |c| [c['project_hud_id'], c.dig('options', 'receives_direct_referrals_from')] }).to eq(
        [[receiver.ProjectID, [sender.ProjectID]]],
      )
      expect(payload['projects'].map { |p| p['ProjectID'] }).to contain_exactly(sender.ProjectID, receiver.ProjectID)
    end

    it 'leaves out a config whose project is deleted, and warns' do
      orphan = create(:hmis_hud_project, data_source: data_source)
      create(:hmis_project_auto_exit_config, data_source: data_source, project: orphan)
      orphan.destroy!

      payload = export(include_ce: false)

      expect(payload['project_configs'].map { |c| c['type'] }).to eq(['Hmis::ProjectCeConfig'])
      expect(payload['warnings']).to include(match(/Hmis::ProjectAutoExitConfig \d+ points at missing or deleted Project/))
    end

    it 'leaves out a CE config whose sending project is deleted, so the restriction is not lost' do
      sender.destroy!

      payload = export(include_ce: false)

      expect(payload['project_configs']).to eq([])
      expect(payload['warnings']).to include(match(/Hmis::ProjectCeConfig \d+ points at missing or deleted Project #{sender.id}/))
    end

    it "doesn't export another data source's configs" do
      create(:hmis_project_auto_exit_config, data_source: other_data_source, project: create(:hmis_hud_project, data_source: other_data_source))

      expect(export(include_ce: false)['project_configs'].size).to eq(1)
    end
  end

  describe 'Coordinated Entry configuration' do
    let!(:definition) { create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT') }
    let!(:step_form) { create(:ce_referral_step_form_definition, data_source: data_source, identifier: 'initial_review') }
    let!(:template) { create(:hmis_workflow_definition_template, data_source: data_source, identifier: 'ours') }
    let!(:project) { create(:hmis_hud_project, data_source: data_source) }
    let!(:other_project) { create(:hmis_hud_project, data_source: other_data_source) }

    before do
      create(:hmis_workflow_definition_user_task, template: template, form_definition_identifier: step_form.identifier)
      other_template = create(:hmis_workflow_definition_template, data_source: other_data_source, identifier: 'theirs')
      create(:hmis_workflow_definition_user_task, template: other_template)
      create(:hmis_unit_group, project: project, name: 'Ours', workflow_template: template)
      create(:hmis_unit_group, project: other_project, name: 'Theirs', workflow_template: other_template)
      create(:hmis_ce_eligibility_requirement, owner: project, name: 'ours')
      create(:hmis_ce_eligibility_requirement, owner: other_project, name: 'theirs')
      create(:hmis_ce_eligibility_requirement, owner: other_data_source, name: 'theirs too')
    end

    it "exports this data source's templates, unit groups, and match rules only" do
      ce = export(identifiers: ['pets'])['ce']

      expect(ce['workflow_templates'].map { |t| t['identifier'] }).to eq(['ours'])
      expect(ce['unit_groups'].map { |g| g['name'] }).to eq(['Ours'])
      expect(ce['match_rules'].map { |r| r['name'] }).to eq(['ours'])
    end

    it 'adds the forms the exported workflow templates use, even when IDENTIFIERS leaves them out' do
      payload = export(identifiers: ['pets'])

      expect(payload['definitions'].map { |d| d['identifier'] }).to contain_exactly('pets', 'initial_review')
    end
  end

  describe 'pick list data' do
    let!(:definition) { create(:hmis_form_definition, data_source: data_source, role: 'CUSTOM_ASSESSMENT') }
    let!(:category) { create(:hmis_custom_service_category, data_source: data_source, name: 'Flex Funds') }

    before do
      create(:hmis_custom_service_type, data_source: data_source, custom_service_category: category, name: 'Rent')
      create(:hmis_custom_service_type, data_source: other_data_source, name: 'Elsewhere')
      GrdaWarehouse::AvailableFileTag.create!(name: 'ROI', group: 'Consent')
    end

    it 'exports custom service types from its own data source, even ones no rule uses' do
      expect(export['service_types'].map { |t| [t['name'], t['category_name']] }).to eq([['Rent', 'Flex Funds']])
    end

    it 'exports file tags' do
      expect(export['file_tags'].map { |t| [t['name'], t['group']] }).to eq([['ROI', 'Consent']])
    end
  end
end
