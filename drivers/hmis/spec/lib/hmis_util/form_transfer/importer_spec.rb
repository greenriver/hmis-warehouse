###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisUtil::FormTransfer::Importer do
  let(:data_source) { create(:hmis_data_source) }
  let(:output) { StringIO.new }

  def form_json(*items)
    { 'item' => [{ 'type' => 'GROUP', 'link_id' => 'group', 'item' => items }] }
  end

  def string_item(link_id, custom_field_key: nil)
    item = { 'type' => 'STRING', 'link_id' => link_id, 'text' => link_id.humanize }
    item['mapping'] = { 'custom_field_key' => custom_field_key } if custom_field_key
    item
  end

  def export(from: data_source, **options)
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'export.json')
      HmisUtil::FormTransfer::Exporter.new(data_source_id: from.id, output: StringIO.new, **options).write(path)
      JSON.parse(File.read(path))
    end
  end

  def import(payload, into: data_source, **options)
    described_class.new(payload, data_source_id: into.id, output: output, **options).run
  end

  # Removes what an export of `source` would contain, so an import starts from an empty installation.
  def wipe(source)
    Hmis::Form::Instance.where(data_source_id: source.id).delete_all
    Hmis::Form::Definition.with_deleted.where(data_source_id: source.id).delete_all
    Hmis::Hud::CustomDataElementDefinition.with_deleted.where(data_source_id: source.id).delete_all
    Hmis::ProjectConfig.with_deleted.where(data_source_id: source.id).delete_all
    [Hmis::Hud::Funder, Hmis::Hud::ProjectCoc, Hmis::Hud::Inventory, Hmis::Hud::Project, Hmis::Hud::Organization].each do |klass|
      klass.with_deleted.where(data_source_id: source.id).delete_all
    end
  end

  def snapshot(source)
    {
      definitions: Hmis::Form::Definition.where(data_source_id: source.id).order(:identifier, :version).map { |d| d.slice(:identifier, :version, :status, :role, :title, :definition) },
      cdeds: Hmis::Hud::CustomDataElementDefinition.where(data_source_id: source.id).order(:key).map { |c| c.slice(:owner_type, :key, :field_type, :label, :repeats, :form_definition_identifier, :reporting_key) },
      rules: Hmis::Form::Instance.where(data_source_id: source.id).preload(:entity).map { |r| [r.definition_identifier, r.entity.try(:ProjectID), r.project_type] }.sort_by(&:to_s),
      projects: Hmis::Hud::Project.where(data_source_id: source.id).order(:ProjectID).map { |p| p.slice(:ProjectID, :ProjectName, :ProjectType, :OrganizationID, :DateCreated) },
      funders: Hmis::Hud::Funder.where(data_source_id: source.id).order(:FunderID).map { |f| f.slice(:FunderID, :ProjectID, :Funder, :StartDate, :DateCreated) },
    }
  end

  describe 'round trip into an empty installation' do
    let!(:definition) do
      create(
        :hmis_form_definition,
        data_source: data_source,
        identifier: 'pets',
        role: 'CUSTOM_ASSESSMENT',
        version: 2,
        definition: form_json(string_item('pet_name', custom_field_key: 'pet_name')),
      )
    end
    let!(:retired_version) { create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT', version: 1, status: 'retired') }
    let!(:cded) do
      create(:hmis_custom_data_element_definition, data_source: data_source, owner_type: 'Hmis::Hud::CustomAssessment', key: 'pet_name', field_type: 'string', reporting_key: 'pet_name', form_definition_identifier: 'pets')
    end
    let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectName: 'Oak House') }
    let!(:funder) { create(:hmis_hud_funder, data_source: data_source, project: project, Funder: 2, DateCreated: Time.zone.parse('2024-03-05 10:11:12')) }

    before do
      create(:hmis_form_instance, data_source: data_source, definition: definition, entity: project)
      create(:hmis_form_instance, data_source: data_source, definition: definition, entity: nil, project_type: 1)
    end

    it 'recreates the definitions, CDEDs, rules, projects, and funders exactly' do
      payload = export(identifiers: ['pets'])
      before_wipe = snapshot(data_source)
      wipe(data_source)

      import(payload)

      expect(snapshot(data_source)).to eq(before_wipe)
    end

    it 'changes nothing when the same file is imported twice' do
      payload = export(identifiers: ['pets'])
      wipe(data_source)
      import(payload)
      first = snapshot(data_source)
      updated_at = Hmis::Hud::Project.where(data_source_id: data_source.id).pluck(:id, :DateUpdated)

      import(payload)

      expect(snapshot(data_source)).to eq(first)
      expect(Hmis::Hud::Project.where(data_source_id: data_source.id).pluck(:id, :DateUpdated)).to eq(updated_at)
      expect(Hmis::Form::Instance.where(data_source_id: data_source.id).count).to eq(2)
    end
  end

  describe 'definition versions' do
    let(:payload) do
      create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT', version: 5, status: 'published')
      create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT', version: 6, status: 'draft')
      export(identifiers: ['pets'], include_projects: false).tap { wipe(data_source) }
    end

    it 'retires a different local published version and soft-deletes a different local draft to make room' do
      payload
      local_published = create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT', version: 1, status: 'published')
      local_draft = create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT', version: 2, status: 'draft')

      import(payload)

      expect(local_published.reload.status).to eq('retired')
      expect(Hmis::Form::Definition.with_deleted.find(local_draft.id).deleted_at).not_to be_nil
      expect(Hmis::Form::Definition.where(data_source_id: data_source.id, identifier: 'pets').order(:version).pluck(:version, :status)).to eq(
        [[1, 'retired'], [5, 'published'], [6, 'draft']],
      )
    end

    it 'overwrites a local definition with the same version' do
      payload
      local = create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT', version: 5, status: 'published', title: 'Local edit')

      import(payload)

      expect(local.reload.title).to eq('Form')
    end
  end

  describe 'CDEDs' do
    let(:payload) do
      create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT')
      create(:hmis_custom_data_element_definition, data_source: data_source, owner_type: 'Hmis::Hud::CustomAssessment', key: 'pet_name', reporting_key: 'pet_name', form_definition_identifier: 'pets')
      export(identifiers: ['pets'], include_projects: false).tap { wipe(data_source) }
    end

    it 'picks a new reporting_key when a different local CDED already uses it' do
      payload
      create(:hmis_custom_data_element_definition, data_source: data_source, owner_type: 'Hmis::Hud::CustomAssessment', key: 'local_field', reporting_key: 'pet_name')

      import(payload)

      expect(Hmis::Hud::CustomDataElementDefinition.find_by(key: 'pet_name').reporting_key).to eq('pet_name_1')
    end

    it "leaves another data source's CDED with the same key alone and warns" do
      payload
      other_data_source = create(:hmis_data_source)
      theirs = create(:hmis_custom_data_element_definition, data_source: other_data_source, owner_type: 'Hmis::Hud::CustomAssessment', key: 'pet_name', label: 'Theirs')

      import(payload)

      expect(theirs.reload.slice(:data_source_id, :label)).to eq('data_source_id' => other_data_source.id, 'label' => 'Theirs')
      expect(output.string).to include('SKIP CDED Hmis::Hud::CustomAssessment/pet_name: key belongs to data source')
    end
  end

  describe 'service types' do
    it 'creates a category that only a rule references' do
      definition = create(:hmis_form_definition, data_source: data_source, identifier: 'bulk_service', role: 'SERVICE')
      category = create(:hmis_custom_service_category, data_source: data_source, name: 'Shelter Services')
      create(:hmis_form_instance, data_source: data_source, definition: definition, entity: nil, custom_service_category: category)
      payload = export(identifiers: ['bulk_service'], include_projects: false)
      wipe(data_source)
      category.really_destroy!

      import(payload)

      rule = Hmis::Form::Instance.find_by(data_source_id: data_source.id, definition_identifier: 'bulk_service')
      expect(rule.custom_service_category.slice(:name, :data_source_id)).to eq('name' => 'Shelter Services', 'data_source_id' => data_source.id)
    end
  end

  describe 'projects whose HUD IDs are taken locally' do
    let!(:definition) { create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT') }
    let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectName: 'Oak House') }
    let!(:funder) { create(:hmis_hud_funder, data_source: data_source, project: project) }

    before { create(:hmis_form_instance, data_source: data_source, definition: definition, entity: project) }

    it 'copies the project under a new HUD ID, prefixes its name, and leaves the local project alone' do
      payload = export(identifiers: ['pets'])
      Hmis::Form::Instance.where(data_source_id: data_source.id).delete_all

      import(payload, name_prefix: 'REAL - ')

      copy = Hmis::Hud::Project.find_by!(data_source_id: data_source.id, ProjectName: 'REAL - Oak House')
      expect(copy.ProjectID).to eq("R1-#{project.ProjectID}")
      expect(copy.organization.OrganizationName).to eq("REAL - #{project.organization.OrganizationName}")
      expect(copy.funders.map(&:FunderID)).to eq(["R1-#{funder.FunderID}"])
      expect(project.reload.ProjectName).to eq('Oak House')
      expect(Hmis::Form::Instance.find_by!(data_source_id: data_source.id, definition_identifier: 'pets').entity).to eq(copy)
    end

    it 'matches the existing project when the name is the same' do
      payload = export(identifiers: ['pets'])

      import(payload, name_prefix: nil)

      expect(Hmis::Hud::Project.where(data_source_id: data_source.id).pluck(:ProjectID)).to contain_exactly(project.ProjectID)
    end

    it 'prefixes names with "REAL - " by default in development only' do
      payload = export(identifiers: ['pets'])
      allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new('development'))

      import(payload)

      expect(Hmis::Hud::Project.where(data_source_id: data_source.id).pluck(:ProjectName)).to contain_exactly('Oak House', 'REAL - Oak House')
    end

    it 'does not prefix names by default outside development' do
      payload = export(identifiers: ['pets'])

      import(payload)

      expect(Hmis::Hud::Project.where(data_source_id: data_source.id).pluck(:ProjectName)).to contain_exactly('Oak House')
    end
  end

  describe 'importing into another data source' do
    let(:target) { create(:hmis_data_source) }

    it "creates records in the target data source without touching the source's" do
      definition = create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT')
      project = create(:hmis_hud_project, data_source: data_source)
      create(:hmis_form_instance, data_source: data_source, definition: definition, entity: project)
      before_import = snapshot(data_source)

      import(export(identifiers: ['pets']), into: target)

      expect(snapshot(data_source)).to eq(before_import)
      expect(Hmis::Hud::Project.where(data_source_id: target.id).pluck(:ProjectID)).to eq([project.ProjectID])
      expect(Hmis::Form::Instance.find_by!(data_source_id: target.id).entity.data_source_id).to eq(target.id)
    end
  end

  describe 'columns the file can set' do
    let(:other_data_source) { create(:hmis_data_source) }

    it 'ignores data_source_id and id on definitions, organizations, projects, funders, and file tags' do
      definition = create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT')
      project = create(:hmis_hud_project, data_source: data_source)
      funder = create(:hmis_hud_funder, data_source: data_source, project: project)
      create(:hmis_form_instance, data_source: data_source, definition: definition, entity: project)
      tag = GrdaWarehouse::AvailableFileTag.create!(name: 'ROI', group: 'Consent')
      payload = export(identifiers: ['pets'])
      injected = { 'data_source_id' => other_data_source.id, 'id' => 999_999 }
      [payload['definitions'], payload['organizations'], payload['projects'], payload['projects'].flat_map { |p| p['funders'] }, payload['file_tags']].flatten.each { |attrs| attrs.merge!(injected) }

      import(payload, name_prefix: nil)

      expect([definition, project, project.organization, funder].map { |record| record.reload.data_source_id }.uniq).to eq([data_source.id])
      expect(tag.reload.id).not_to eq(999_999)
      expect(GrdaWarehouse::AvailableFileTag.where(name: 'ROI').pluck(:id)).to eq([tag.id])
    end
  end

  it 'skips a project whose organization is not in the file' do
    definition = create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT')
    create(:hmis_form_instance, data_source: data_source, definition: definition, entity: create(:hmis_hud_project, data_source: data_source, ProjectName: 'Orphan'))
    payload = export(identifiers: ['pets'])
    payload['organizations'] = []
    wipe(data_source)

    import(payload)

    expect(Hmis::Hud::Project.where(data_source_id: data_source.id).count).to eq(0)
    expect(output.string).to include('SKIP project Orphan: its organization is not in the file')
  end

  it 'refuses a data source that is not an HMIS data source' do
    warehouse_only = create(:grda_warehouse_data_source)

    expect { described_class.new({ 'format_version' => 3 }, data_source_id: warehouse_only.id, output: output) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  describe 'a failed import' do
    it 'rolls back changes in both databases' do
      create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT')
      AppConfigProperty.create!(key: 'hmis_ce/enabled', value: true)
      payload = export(identifiers: ['pets'], include_projects: false)
      payload['project_configs'] = [{ 'type' => 'Hmis::NotAConfig', 'project_type' => 1 }]
      wipe(data_source)
      AppConfigProperty.where(key: 'hmis_ce/enabled').delete_all

      expect { import(payload) }.to raise_error(RuntimeError, 'Unknown project config type Hmis::NotAConfig')
      expect(Hmis::Form::Definition.where(data_source_id: data_source.id).count).to eq(0)
      expect(AppConfigProperty.where(key: 'hmis_ce/enabled').count).to eq(0)
    end
  end

  describe 'dry run' do
    it 'rolls back changes in both the warehouse and the primary database' do
      create(:hmis_form_definition, data_source: data_source, identifier: 'pets', role: 'CUSTOM_ASSESSMENT')
      AppConfigProperty.create!(key: 'hmis_ce/enabled', value: true)
      payload = export(identifiers: ['pets'])
      wipe(data_source)
      AppConfigProperty.where(key: 'hmis_ce/enabled').delete_all

      import(payload, dry_run: true)

      expect(Hmis::Form::Definition.where(data_source_id: data_source.id).count).to eq(0)
      expect(AppConfigProperty.where(key: 'hmis_ce/enabled').count).to eq(0)
      expect(output.string).to include('DRY_RUN: rolled back')
    end
  end

  describe 'environment gate' do
    let(:payload) do
      create(:hmis_form_definition, data_source: data_source, role: 'CUSTOM_ASSESSMENT')
      export(include_projects: false)
    end

    def in_environment(name)
      allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new(name))
    end

    it 'refuses outside development without confirmation' do
      payload
      in_environment('staging')

      expect { import(payload) }.to raise_error(RuntimeError, /Refusing to import outside development/)
    end

    it 'refuses when the confirmation names a different environment' do
      payload
      in_environment('production')

      expect { import(payload, confirm_environment: 'staging') }.to raise_error(RuntimeError, /Refusing to import outside development/)
    end

    it 'runs when the confirmation matches the environment' do
      payload
      wipe(data_source)
      in_environment('staging')

      import(payload, confirm_environment: 'staging')

      expect(Hmis::Form::Definition.where(data_source_id: data_source.id).count).to eq(1)
    end

    it 'refuses before writing anything' do
      payload
      wipe(data_source)
      in_environment('staging')

      expect { import(payload) }.to raise_error(RuntimeError)
      expect(Hmis::Form::Definition.where(data_source_id: data_source.id).count).to eq(0)
    end
  end

  it 'rejects an unknown format version' do
    expect { described_class.new({ 'format_version' => 99 }, data_source_id: data_source.id, output: output) }.
      to raise_error(RuntimeError, 'Unsupported format_version 99, expected one of [2, 3]')
  end
end
