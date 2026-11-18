###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HmisUtil::FormTransfer Coordinated Entry configuration' do
  let(:data_source) { create(:hmis_data_source) }
  let(:output) { StringIO.new }
  let(:system_user) { User.system_user }

  let!(:step_form) { create(:ce_referral_step_form_definition, data_source: data_source, identifier: 'initial_review') }
  let!(:sender) { create(:hmis_hud_project, data_source: data_source, ProjectName: 'Sender') }
  let!(:receiver) { create(:hmis_hud_project, data_source: data_source, ProjectName: 'Receiver') }
  let!(:template) { create(:hmis_workflow_definition_template, data_source: data_source, identifier: 'direct_referral', version: 0) }
  let!(:unit_type) { create(:hmis_unit_type, description: 'Single Bed', bed_type: 13, unit_size: 1) }

  before do
    swimlane = create(:hmis_workflow_definition_swimlane, template: template, name: 'Provider')
    start_event = create(:hmis_workflow_definition_start_event, template: template, name: 'Start')
    task = create(:hmis_workflow_definition_user_task, template: template, name: 'Review', form_definition_identifier: step_form.identifier, swimlane_id: swimlane.id)
    end_event = create(:hmis_workflow_definition_end_event, template: template, name: 'End')
    create(:hmis_workflow_definition_flow, template: template, source_node: start_event, target_node: task, position: 0)
    create(:hmis_workflow_definition_flow, template: template, source_node: task, target_node: end_event, position: 0, condition: 'approved')

    create(:hmis_ce_custom_referral_status, data_source: data_source, key: 'waiting', name: 'Waiting')
    create(:ce_referral_decline_reason, data_source: data_source, key: 'no_contact', name: 'No contact')

    create(:hmis_project_ce_config, data_source: data_source, project: receiver, receives_direct_referrals: true, receives_direct_referrals_from: [sender.id])
    create(:hmis_project_sends_direct_ce_referrals_config, data_source: data_source, project: sender)
    Hmis::ProjectUnitTypeMapping.create!(project: receiver, unit_type: unit_type, unit_capacity: 3, active: true)

    group = Hmis::UnitGroup.create!(project: receiver, name: 'Beds', unit_type: unit_type, direct_referral_workflow_template_identifier: template.identifier)
    2.times { Hmis::Unit.create!(project: receiver, unit_group: group, unit_type: unit_type, user: system_user) }
    closed = Hmis::Unit.create!(project: receiver, unit_group: group, unit_type: unit_type, user: system_user)
    closed.active_ranges.create!(start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 6, 30), user_id: system_user.id.to_s)

    eligibility_group = create(:hmis_project_group, data_source: data_source, name: 'CE Eligible', inclusion_criteria: { project_ids: [receiver.id.to_s] }.to_json)
    eligibility_group.maintain_projects!
    AppConfigProperty.create!(key: 'hmis_ce/enabled', value: true)
    AppConfigProperty.create!(key: 'hmis_ce/eligibility_project_group_id', value: eligibility_group.id)

    create(:hmis_ce_eligibility_requirement, owner: data_source, name: 'Adults', expression: 'current_age >= 18')
    create(:hmis_ce_eligibility_requirement, owner: receiver, name: 'Over 21', expression: 'current_age >= 21')
    create(:hmis_ce_priority_scheme, owner: group, name: 'Longest homeless', expression: 'days_homeless', priority_rank: 1)
  end

  def export
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'export.json')
      HmisUtil::FormTransfer::Exporter.new(data_source_id: data_source.id, identifiers: [step_form.identifier], output: StringIO.new).write(path)
      JSON.parse(File.read(path))
    end
  end

  def import(payload)
    HmisUtil::FormTransfer::Importer.new(payload, data_source_id: data_source.id, output: output).run
  end

  def graph(template)
    nodes = Hmis::WorkflowDefinition::Node.where(template_id: template.id).to_h do |node|
      [node.id, [node.type, node.name, node.form_definition_identifier, node.trigger_config, Hmis::WorkflowDefinition::Swimlane.find_by(id: node.swimlane_id)&.name]]
    end
    flows = Hmis::WorkflowDefinition::Flow.where(template_id: template.id).map { |f| [nodes[f.source_node_id], nodes[f.target_node_id], f.condition, f.position] }
    { nodes: nodes.values.sort_by(&:to_s), flows: flows.sort_by(&:to_s), template: template.slice(:name, :status, :template_type) }
  end

  def wipe_ce
    template_ids = Hmis::WorkflowDefinition::Template.where(data_source_id: data_source.id).pluck(:id)
    [Hmis::WorkflowDefinition::Flow, Hmis::WorkflowDefinition::Node, Hmis::WorkflowDefinition::Swimlane].each { |k| k.with_deleted.where(template_id: template_ids).delete_all }
    Hmis::WorkflowDefinition::Template.with_deleted.where(id: template_ids).delete_all
    Hmis::Ce::Match::Rule.with_deleted.delete_all
    Hmis::ActiveRange.with_deleted.where(entity_type: 'Hmis::Unit').delete_all
    Hmis::Unit.with_deleted.delete_all
    Hmis::UnitGroup.with_deleted.delete_all
    Hmis::ProjectUnitTypeMapping.delete_all
    Hmis::UnitType.with_deleted.delete_all
    Hmis::ProjectConfig.with_deleted.where(data_source_id: data_source.id).delete_all
    Hmis::ProjectGroup.with_deleted.where(data_source_id: data_source.id).each { |group| group.projects = [] }
    Hmis::ProjectGroup.with_deleted.where(data_source_id: data_source.id).delete_all
    Hmis::Ce::CustomReferralStatus.with_deleted.where(data_source_id: data_source.id).delete_all
    Hmis::Ce::ReferralDeclineReason.with_deleted.where(data_source_id: data_source.id).delete_all
    AppConfigProperty.where('key LIKE ?', 'hmis_ce/%').delete_all
  end

  describe 'round trip into an installation with the same projects but no CE setup' do
    let(:payload) { export }
    let(:graph_before) { graph(template) }

    before do
      payload
      graph_before
      wipe_ce
      import(payload)
    end

    it 'rebuilds the workflow template graph' do
      rebuilt = Hmis::WorkflowDefinition::Template.find_by!(identifier: 'direct_referral', version: 0)

      expect([rebuilt.data_source_id, graph(rebuilt)]).to eq([data_source.id, graph_before])
    end

    it 'points receives_direct_referrals_from at the local sending project' do
      config = Hmis::ProjectCeConfig.find_by!(project_id: receiver.id)

      expect(config.receives_direct_referrals_from).to eq([sender.id])
      expect(Hmis::ProjectSendsDirectCeReferralsConfig.where(project_id: sender.id).count).to eq(1)
    end

    it 'recreates the unit group, its units, and the closed unit range' do
      group = Hmis::UnitGroup.find_by!(project_id: receiver.id, name: 'Beds')

      expect(group.slice(:direct_referral_workflow_template_identifier, :unit_type_id)).to eq(
        'direct_referral_workflow_template_identifier' => 'direct_referral', 'unit_type_id' => Hmis::UnitType.find_by!(description: 'Single Bed').id,
      )
      expect(Hmis::Unit.where(hmis_unit_group_id: group.id).count).to eq(3)
      expect(Hmis::Unit.where(hmis_unit_group_id: group.id).active.count).to eq(2)
      expect(Hmis::ProjectUnitTypeMapping.where(project_id: receiver.id).pluck(:unit_capacity, :active)).to eq([[3, true]])
    end

    it 'attaches match rules to their owners' do
      group = Hmis::UnitGroup.find_by!(project_id: receiver.id, name: 'Beds')

      expect(Hmis::Ce::Match::Rule.all.map { |r| [r.owner, r.name, r.expression, r.priority_rank] }).to contain_exactly(
        [data_source, 'Adults', 'current_age >= 18', nil],
        [receiver, 'Over 21', 'current_age >= 21', nil],
        [group, 'Longest homeless', 'days_homeless', 1],
      )
    end

    it 'restores the eligibility group by name and points the setting at its new id' do
      group = Hmis::ProjectGroup.find_by!(data_source_id: data_source.id, name: 'CE Eligible')

      expect(AppConfigProperty.find_by!(key: 'hmis_ce/eligibility_project_group_id').value).to eq(group.id)
      expect(group.projects).to contain_exactly(receiver)
      expect(AppConfigProperty.find_by!(key: 'hmis_ce/enabled').value).to eq(true)
    end

    it 'restores referral statuses and decline reasons' do
      expect(Hmis::Ce::CustomReferralStatus.where(data_source_id: data_source.id).pluck(:key, :name)).to eq([['waiting', 'Waiting']])
      expect(Hmis::Ce::ReferralDeclineReason.where(data_source_id: data_source.id).pluck(:key, :name)).to eq([['no_contact', 'No contact']])
    end

    it 'creates nothing on a second import' do
      counts = lambda do
        [
          Hmis::Unit, Hmis::UnitGroup, Hmis::UnitType, Hmis::ProjectUnitTypeMapping, Hmis::ActiveRange, Hmis::Ce::Match::Rule, Hmis::ProjectConfig,
          Hmis::WorkflowDefinition::Template, Hmis::WorkflowDefinition::Node, Hmis::WorkflowDefinition::Flow, Hmis::ProjectGroup, AppConfigProperty,
          Hmis::Ce::CustomReferralStatus, Hmis::Ce::ReferralDeclineReason, Hmis::Form::Instance, Hmis::Form::Definition
        ].map(&:count)
      end

      expect { import(payload) }.not_to change(&counts)
    end
  end

  it 'leaves an existing template with the same identifier and version alone' do
    payload = export
    original_ids = Hmis::WorkflowDefinition::Node.where(template_id: template.id).pluck(:id)

    import(payload)

    expect(Hmis::WorkflowDefinition::Node.where(template_id: template.id).pluck(:id)).to match_array(original_ids)
    expect(Hmis::WorkflowDefinition::Template.where(identifier: 'direct_referral').count).to eq(1)
    expect(output.string).to include('exists workflow template direct_referral v0')
  end

  it "keeps a unit group's local template identifier when the source has a different one" do
    payload = export
    payload['ce']['unit_groups'].first['direct_referral_workflow_template_identifier'] = 'something_else'

    import(payload)

    expect(Hmis::UnitGroup.find_by!(project_id: receiver.id).direct_referral_workflow_template_identifier).to eq('direct_referral')
    expect(output.string).to include('keeping local direct_referral_workflow_template_identifier "direct_referral" on unit group Beds')
  end

  it 'adds only the units a project is missing and never removes extra local units' do
    payload = export
    group = Hmis::UnitGroup.find_by!(project_id: receiver.id)
    open_units = Hmis::Unit.where(hmis_unit_group_id: group.id).left_outer_joins(:active_ranges).where(hmis_active_ranges: { id: nil })
    Hmis::Unit.where(id: open_units.first.id).delete_all
    3.times { Hmis::Unit.create!(project: receiver, unit_group: group, unit_type: unit_type, name: 'Local', user: system_user) }

    import(payload)

    expect(Hmis::Unit.where(hmis_unit_group_id: group.id).group(:name).count).to eq(nil => 3, 'Local' => 3)
  end

  describe 'receives_direct_referrals_from' do
    it 'skips the config when a sending project is not found locally, keeping the local restriction' do
      payload = export
      config = payload['project_configs'].find { |c| c['type'] == 'Hmis::ProjectCeConfig' }
      config['options']['receives_direct_referrals_from'] = ['not-a-local-project']

      import(payload)

      expect(Hmis::ProjectCeConfig.find_by!(project_id: receiver.id).receives_direct_referrals_from).to eq([sender.id])
      expect(output.string).to include('SKIP ProjectCeConfig for')
    end
  end

  it 'skips a project config with no project, organization, or project type' do
    payload = export
    payload['project_configs'] << { 'type' => 'Hmis::ProjectAutoExitConfig', 'project_hud_id' => nil, 'organization_hud_id' => nil, 'project_type' => nil, 'options' => nil }

    import(payload)

    expect(output.string).to include('SKIP ProjectAutoExitConfig: no project, organization, or project type')
  end

  it 'skips a match rule whose priority_rank another local rule on the same owner holds' do
    payload = export
    group = Hmis::UnitGroup.find_by!(project_id: receiver.id)
    Hmis::Ce::Match::Rule.where(name: 'Longest homeless').delete_all
    create(:hmis_ce_priority_scheme, owner: group, name: 'Local scheme', expression: 'days_homeless', priority_rank: 1)

    import(payload)

    expect(Hmis::Ce::Match::Rule.where(owner: group).pluck(:name)).to eq(['Local scheme'])
    expect(output.string).to include('SKIP match rule Longest homeless: priority_rank 1 is held by Local scheme')
  end

  it 'skips a unit group that fails validation instead of aborting the import' do
    create(:hmis_workflow_definition_template, data_source: create(:hmis_data_source), identifier: 'elsewhere')
    payload = export
    payload['ce']['unit_groups'].first['name'] = 'New beds'
    payload['ce']['unit_groups'].first['workflow_template_identifier'] = 'elsewhere'
    payload['ce']['units'] = []
    payload['ce']['match_rules'] = []

    import(payload)

    expect(Hmis::UnitGroup.where(project_id: receiver.id).pluck(:name)).to eq(['Beds'])
    expect(output.string).to include('SKIP unit group New beds: Workflow template identifier must belong to the same data source')
  end

  it 'restores a soft-deleted local unit group with the same name' do
    payload = export
    group = Hmis::UnitGroup.find_by!(project_id: receiver.id)
    Hmis::Unit.where(hmis_unit_group_id: group.id).update_all(hmis_unit_group_id: nil)
    group.update_columns(deleted_at: Time.current)

    import(payload)

    expect(Hmis::UnitGroup.where(project_id: receiver.id).pluck(:id)).to eq([group.id])
  end

  it 'skips a template version that exists locally as a soft-deleted row' do
    payload = export
    Hmis::UnitGroup.update_all(deleted_at: Time.current)
    template.update_columns(deleted_at: Time.current)

    import(payload)

    expect(Hmis::WorkflowDefinition::Template.with_deleted.where(identifier: 'direct_referral').count).to eq(1)
    expect(output.string).to include('SKIP workflow template direct_referral v0 (published): a soft-deleted local copy exists')
  end

  it 'leaves CE configuration out of the export when include_ce is false' do
    payload = Dir.mktmpdir do |dir|
      path = File.join(dir, 'export.json')
      HmisUtil::FormTransfer::Exporter.new(data_source_id: data_source.id, include_ce: false, output: StringIO.new).write(path)
      JSON.parse(File.read(path))
    end

    expect(payload['ce']).to eq({})
  end
end
