###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Bootstrapper do
  let!(:data_source) { create(:hmis_data_source) }

  let(:base_config) do
    {
      'name' => 'Test CoC',
      'data_source_id' => data_source.id,
      'seed' => 42,
      'coc_codes' => { 'primary' => 'XX-500' },
      'organizations' => [
        {
          'name' => 'Test Org_',
          'projects' => [
            { 'name' => 'Test ES NBN_', 'project_type' => 1, 'capacity' => 20 },
            {
              'name' => 'Test PSH_', 'project_type' => 3, 'capacity' => 10,
              'funders' => [{ 'funder' => 3, 'grant_id' => 'FAKE-GRANT-001_' }]
            },
            { 'name' => 'Test SO_', 'project_type' => 4 },
            { 'name' => 'Test CE_', 'project_type' => 14 },
          ],
        },
      ],
      'tracks' => [
        {
          'name' => 'general',
          'type' => 'primary',
          'new_clients_per_month' => { 'distribution' => 'constant', 'value' => 5 },
          'household_templates' => {
            'adult_only' => { 'hoh' => { 'age' => { 'distribution' => 'uniform', 'min' => 25, 'max' => 55 } } },
          },
          'populations' => [
            { 'name' => 'street', 'label' => 'Street', 'project_ref' => 'Test SO_',
              'household_templates' => { 'adult_only' => 1 },
              'entry_point' => 1, 'exit_point' => 0.1 },
            { 'name' => 'es', 'label' => 'ES', 'project_ref' => 'Test ES NBN_',
              'household_templates' => { 'adult_only' => 1 },
              'entry_point' => 0, 'exit_point' => 0.1 },
            { 'name' => 'psh', 'label' => 'PSH', 'project_ref' => 'Test PSH_',
              'household_templates' => { 'adult_only' => 1 },
              'entry_point' => 0, 'exit_point' => 0.5 },
          ],
          'transitions' => [
            { 'from' => 'street', 'to' => 'es', 'weight' => 1,
              'timing' => { 'distribution' => 'constant', 'value' => 7 },
              'exit_destinations' => { '101' => 1 } },
            { 'from' => 'es', 'to' => 'psh', 'weight' => 1,
              'timing' => { 'distribution' => 'constant', 'value' => 30 },
              'exit_destinations' => { '435' => 1 } },
          ],
        },
        {
          'name' => 'coordinated_entry',
          'type' => 'lifecycle',
          'applies_to_tracks' => [],
          'project_ref' => 'Test CE_',
          'trigger_populations' => ['street'],
          'trigger_probability' => 0.3,
          'days_before_trigger' => { 'distribution' => 'constant', 'value' => 0 },
          'close_conditions' => { 'housing_move_in' => 1.0 },
        },
      ],
    }
  end

  # Use a normalized copy so weights sum correctly
  let(:config) { HmisSimulation::ConfigLoader.send(:normalize, base_config) }

  before { User.setup_system_user }

  subject(:bootstrapper) { described_class.new(config) }

  def ds_scope(klass)
    klass.where(data_source_id: data_source.id)
  end

  describe '#run!' do
    it 'creates the configured organizations' do
      expect { bootstrapper.run! }.to change { ds_scope(Hmis::Hud::Organization).count }.by(1)
    end

    it 'creates all configured projects' do
      expect { bootstrapper.run! }.to change { ds_scope(Hmis::Hud::Project).count }.by(4)
    end

    it 'creates a ProjectCoc for every project' do
      bootstrapper.run!
      project_count = ds_scope(Hmis::Hud::Project).count
      coc_count = ds_scope(Hmis::Hud::ProjectCoc).count
      expect(coc_count).to eq(project_count)
    end

    it 'creates Inventory only for residential project types' do
      bootstrapper.run!
      # ES (1) and PSH (3) get inventory; SO (4) and CE (14) do not
      expect(ds_scope(Hmis::Hud::Inventory).count).to eq(2)
    end

    it 'creates Funder records when specified in project config' do
      expect { bootstrapper.run! }.to change { ds_scope(Hmis::Hud::Funder).count }.by(1)
    end

    it 'assigns FAKE UUIDs to all HUD identifiers' do
      bootstrapper.run!
      org = ds_scope(Hmis::Hud::Organization).first
      expect(org.OrganizationID).to start_with('FAKE')
      project = ds_scope(Hmis::Hud::Project).first
      expect(project.ProjectID).to start_with('FAKE')
    end

    it 'preserves configured project names exactly (including trailing underscore)' do
      bootstrapper.run!
      names = ds_scope(Hmis::Hud::Project).pluck(:ProjectName).sort
      expect(names).to include('Test ES NBN_', 'Test PSH_', 'Test SO_', 'Test CE_')
    end

    it 'sets the primary CoCCode on all ProjectCoc records' do
      bootstrapper.run!
      cocs = ds_scope(Hmis::Hud::ProjectCoc).pluck(:CoCCode).uniq
      expect(cocs).to include('XX-500')
    end

    it 'creates HmisParticipation for every project' do
      bootstrapper.run!
      project_count = ds_scope(Hmis::Hud::Project).count
      expect(ds_scope(Hmis::Hud::HmisParticipation).count).to eq(project_count)
    end

    it 'sets HMISParticipationType to 1 by default' do
      bootstrapper.run!
      types = ds_scope(Hmis::Hud::HmisParticipation).pluck(:HMISParticipationType).uniq
      expect(types).to eq([1])
    end

    it 'uses hmis_participation_type from project config when present' do
      config_with_type = HmisSimulation::ConfigLoader.send(
        :normalize,
        base_config.deep_merge(
          'organizations' => [
            base_config['organizations'][0].deep_merge(
              'projects' => base_config['organizations'][0]['projects'].map.with_index do |p, i|
                i.zero? ? p.merge('hmis_participation_type' => 2) : p
              end,
            ),
          ],
        ),
      )
      described_class.new(config_with_type).run!
      types = ds_scope(Hmis::Hud::HmisParticipation).pluck(:HMISParticipationType).sort
      expect(types).to include(2)
    end

    it 'creates CeParticipation only for CE projects (type 14)' do
      bootstrapper.run!
      expect(ds_scope(Hmis::Hud::CeParticipation).count).to eq(1)
    end

    it 'does not create CeParticipation for non-CE projects' do
      bootstrapper.run!
      ce_project_ids = ds_scope(Hmis::Hud::Project).where(ProjectType: 14).pluck(:ProjectID)
      non_ce_participations = ds_scope(Hmis::Hud::CeParticipation).
        where.not(ProjectID: ce_project_ids)
      expect(non_ce_participations.count).to eq(0)
    end

    it 'sets ProjectCoC Zip and GeographyType' do
      bootstrapper.run!
      coc = ds_scope(Hmis::Hud::ProjectCoc).first
      expect(coc.Zip).to eq('99901')
      expect(coc.GeographyType).to eq(1)
    end

    it 'sets ESBedType on ES-NBN inventory' do
      bootstrapper.run!
      es_nbn_project = ds_scope(Hmis::Hud::Project).find_by(ProjectType: 1)
      inventory = ds_scope(Hmis::Hud::Inventory).find_by(ProjectID: es_nbn_project.ProjectID)
      expect(inventory.ESBedType).to eq(1)
    end

    it 'sets HMISParticipatingBeds equal to BedInventory' do
      bootstrapper.run!
      ds_scope(Hmis::Hud::Inventory).each do |inv|
        expect(inv.HMISParticipatingBeds).to eq(inv.BedInventory)
      end
    end

    it 'partitions sub-bed counts so they sum to BedInventory' do
      bootstrapper.run!
      ds_scope(Hmis::Hud::Inventory).each do |inv|
        sub_beds = inv.VetBedInventory.to_i + inv.YouthBedInventory.to_i + inv.CHBedInventory.to_i
        expect(sub_beds).to eq(inv.BedInventory), \
                            "Expected sub-beds (#{sub_beds}) to equal BedInventory (#{inv.BedInventory}) for project #{inv.ProjectID}"
      end
    end

    context 'when run twice' do
      it 'is idempotent — creates no duplicate records' do
        bootstrapper.run!

        expect { bootstrapper.run! }.
          to not_change { ds_scope(Hmis::Hud::Organization).count }.
          and not_change { ds_scope(Hmis::Hud::Project).count }.
          and not_change { ds_scope(Hmis::Hud::ProjectCoc).count }.
          and not_change { ds_scope(Hmis::Hud::Inventory).count }.
          and not_change { ds_scope(Hmis::Hud::Funder).count }.
          and not_change { ds_scope(Hmis::Hud::HmisParticipation).count }.
          and(not_change { ds_scope(Hmis::Hud::CeParticipation).count })
      end
    end

    context 'with invalid config' do
      it 'raises ConfigError without writing any records' do
        bad_config = base_config.merge('data_source_id' => nil)
        bootstrapper = described_class.new(bad_config)
        expect { bootstrapper.run! }.
          to raise_error(HmisSimulation::ConfigError).
          and(not_change { ds_scope(Hmis::Hud::Organization).count })
      end
    end

    context 'in production' do
      it 'refuses to write any records' do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        expect { bootstrapper.run! }.
          to raise_error(/production/).
          and(not_change { ds_scope(Hmis::Hud::Organization).count })
      end
    end
  end
end
