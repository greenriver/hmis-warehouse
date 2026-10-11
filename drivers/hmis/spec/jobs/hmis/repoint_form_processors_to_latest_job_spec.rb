###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::RepointFormProcessorsToLatestJob, type: :job do
  let!(:ds) { create(:hmis_primary_data_source) }
  let(:other_ds) { create(:hmis_data_source) }

  # Retired versions + the published version of one form. Returns { retired: [...], published: }
  def create_form(identifier:, role:, data_source: ds, retired_versions: [1], published_version: 2)
    retired = retired_versions.map do |version|
      create(:hmis_form_definition, identifier: identifier, role: role, data_source: data_source, version: version, status: Hmis::Form::Definition::RETIRED)
    end
    published = create(:hmis_form_definition, identifier: identifier, role: role, data_source: data_source, version: published_version, status: Hmis::Form::Definition::PUBLISHED) if published_version
    { retired: retired, published: published }
  end

  def assessment_processor(definition, wip: false, data_source: ds)
    create(:hmis_custom_assessment, data_source: data_source, wip: wip, definition: definition).form_processor
  end

  def note_processor(definition)
    create(:hmis_hud_custom_case_note, data_source: ds, definition: definition).form_processor
  end

  def current_definition_id(processor)
    Hmis::Form::FormProcessor.find(processor.id).definition_id
  end

  def run(**args)
    described_class.perform_now(data_source_id: ds.id, **args)
  end

  before { allow(described_class).to receive(:send_single_notification) }

  describe 'with one retired and one published version per role' do
    let!(:assessment_form) { create_form(identifier: 'my_assessment', role: 'CUSTOM_ASSESSMENT') }
    let!(:note_form) { create_form(identifier: 'my_note', role: 'CASE_NOTE') }
    let!(:service_form) { create_form(identifier: 'my_service', role: 'SERVICE') }
    let!(:cls_form) { create_form(identifier: 'my_cls', role: 'CURRENT_LIVING_SITUATION') }

    let!(:assessment_fp) { assessment_processor(assessment_form[:retired].first) }
    let!(:note_fp) { note_processor(note_form[:retired].first) }
    let!(:service_fp) { create(:hmis_hud_service, data_source: ds, definition: service_form[:retired].first).form_processor }
    let!(:cls_fp) { create(:hmis_current_living_situation, data_source: ds, definition: cls_form[:retired].first).form_processor }

    it 'repoints all four roles to the published version when applied' do
      result = run(dry_run: false)

      expect(current_definition_id(assessment_fp)).to eq(assessment_form[:published].id)
      expect(current_definition_id(note_fp)).to eq(note_form[:published].id)
      expect(current_definition_id(service_fp)).to eq(service_form[:published].id)
      expect(current_definition_id(cls_fp)).to eq(cls_form[:published].id)

      expect(result).to contain_exactly(
        { role: 'CASE_NOTE', identifier: 'my_note', from_version: 1, to_version: 2, processors: 1 },
        { role: 'CURRENT_LIVING_SITUATION', identifier: 'my_cls', from_version: 1, to_version: 2, processors: 1 },
        { role: 'CUSTOM_ASSESSMENT', identifier: 'my_assessment', from_version: 1, to_version: 2, processors: 1 },
        { role: 'SERVICE', identifier: 'my_service', from_version: 1, to_version: 2, processors: 1 },
      )
    end

    it 'is a dry run by default: reports counts and writes nothing' do
      result = nil
      expect { result = described_class.perform_now(data_source_id: ds.id) }.
        not_to(change { Hmis::Form::FormProcessor.order(:id).pluck(:id, :definition_id) })

      expect(result.map { |r| r[:processors] }).to eq([1, 1, 1, 1])
      expect(result.map { |r| r[:identifier] }).to eq(['my_note', 'my_cls', 'my_assessment', 'my_service']) # ordered by role, then identifier
    end

    it 'only repoints the requested roles' do
      result = run(roles: ['SERVICE'], dry_run: false)

      expect(result.map { |r| r[:role] }).to eq(['SERVICE'])
      expect(current_definition_id(service_fp)).to eq(service_form[:published].id)
      expect(current_definition_id(assessment_fp)).to eq(assessment_form[:retired].first.id)
      expect(current_definition_id(note_fp)).to eq(note_form[:retired].first.id)
      expect(current_definition_id(cls_fp)).to eq(cls_form[:retired].first.id)
    end

    it 'only repoints the requested identifiers' do
      result = run(identifiers: ['my_note'], dry_run: false)

      expect(result.map { |r| r[:identifier] }).to eq(['my_note'])
      expect(current_definition_id(note_fp)).to eq(note_form[:published].id)
      expect(current_definition_id(service_fp)).to eq(service_form[:retired].first.id)
    end

    it 'is a no-op when run again' do
      run(dry_run: false)

      result = nil
      expect { result = run(dry_run: false) }.
        not_to(change { Hmis::Form::FormProcessor.order(:id).pluck(:id, :definition_id) })
      expect(result.sum { |r| r[:processors] }).to eq(0)
    end

    it 'sends a notification only when applied' do
      run
      expect(described_class).not_to have_received(:send_single_notification)

      run(dry_run: false)
      expect(described_class).to have_received(:send_single_notification).once.with(a_string_including('4 processors'), anything)
    end
  end

  describe 'processors that must be left alone' do
    let!(:form) { create_form(identifier: 'my_assessment', role: 'CUSTOM_ASSESSMENT') }
    let(:retired) { form[:retired].first }
    let(:published) { form[:published] }

    it 'skips work-in-progress assessments when applied' do
      wip_fp = assessment_processor(retired, wip: true)
      final_fp = assessment_processor(retired)

      result = run(dry_run: false)

      expect(current_definition_id(wip_fp)).to eq(retired.id)
      expect(current_definition_id(final_fp)).to eq(published.id)
      expect(result.sole[:processors]).to eq(1)
    end

    it 'does not count work-in-progress assessments in a dry run' do
      assessment_processor(retired, wip: true)
      assessment_processor(retired)
      assessment_processor(retired)

      expect(run.sole[:processors]).to eq(2)
    end

    it 'skips retired definitions with no published version' do
      orphan = create_form(identifier: 'orphan_note', role: 'CASE_NOTE', published_version: nil)[:retired].first
      orphan_fp = note_processor(orphan)

      result = run(dry_run: false)

      expect(result.map { |r| r[:identifier] }).not_to include('orphan_note')
      expect(current_definition_id(orphan_fp)).to eq(orphan.id)
    end

    it 'does not move processors off a published or draft definition' do
      published_fp = assessment_processor(published)
      draft = create(:hmis_form_definition, identifier: 'my_assessment', role: 'CUSTOM_ASSESSMENT', data_source: ds, version: 3, status: Hmis::Form::Definition::DRAFT)
      draft_fp = assessment_processor(draft)

      run(dry_run: false)

      expect(current_definition_id(published_fp)).to eq(published.id)
      expect(current_definition_id(draft_fp)).to eq(draft.id)
    end

    it 'does not touch roles outside the supported roles' do
      intake = create_form(identifier: 'my_intake', role: 'INTAKE')
      intake_fp = assessment_processor(intake[:retired].first)

      result = run(dry_run: false)

      expect(result.map { |r| r[:identifier] }).to eq(['my_assessment'])
      expect(current_definition_id(intake_fp)).to eq(intake[:retired].first.id)
    end

    it 'does not touch other data sources' do
      other = create_form(identifier: 'my_assessment', role: 'CUSTOM_ASSESSMENT', data_source: other_ds)
      other_fp = assessment_processor(other[:retired].first, data_source: other_ds)
      mine_fp = assessment_processor(retired)

      run(dry_run: false)

      expect(current_definition_id(mine_fp)).to eq(published.id)
      expect(current_definition_id(other_fp)).to eq(other[:retired].first.id)
    end
  end

  describe 'several retired versions of one form' do
    it 'moves every retired version to the one published version' do
      form = create_form(identifier: 'my_note', role: 'CASE_NOTE', retired_versions: [1, 2], published_version: 3)
      fps = form[:retired].map { |definition| note_processor(definition) }

      result = run(dry_run: false)

      expect(fps.map { |fp| current_definition_id(fp) }).to all(eq(form[:published].id))
      expect(result.map { |r| [r[:from_version], r[:to_version], r[:processors]] }).to eq([[1, 3, 1], [2, 3, 1]])
    end
  end

  describe 'batching' do
    it 'repoints every processor when they span several batches' do
      stub_const("#{described_class}::BATCH_SIZE", 2)
      form_a = create_form(identifier: 'note_a', role: 'CASE_NOTE')
      form_b = create_form(identifier: 'note_b', role: 'CASE_NOTE')
      fps_a = Array.new(3) { note_processor(form_a[:retired].first) }
      fps_b = Array.new(4) { note_processor(form_b[:retired].first) }
      wip_fp = assessment_processor(create_form(identifier: 'asmt', role: 'CUSTOM_ASSESSMENT')[:retired].first, wip: true)

      result = run(dry_run: false)

      expect(fps_a.map { |fp| current_definition_id(fp) }).to all(eq(form_a[:published].id))
      expect(fps_b.map { |fp| current_definition_id(fp) }).to all(eq(form_b[:published].id))
      expect(current_definition_id(wip_fp)).to eq(Hmis::Form::Definition.find_by!(identifier: 'asmt', version: 1).id)
      expect(result.to_h { |r| [r[:identifier], r[:processors]] }).to include('note_a' => 3, 'note_b' => 4, 'asmt' => 0)
    end
  end

  describe 'arguments' do
    it 'rejects unsupported roles before touching data' do
      expect { run(roles: ['INTAKE'], dry_run: false) }.to raise_error(ArgumentError, /unsupported roles: INTAKE/)
    end

    it 'uses the sole HMIS data source when none is given' do
      form = create_form(identifier: 'my_note', role: 'CASE_NOTE')
      fp = note_processor(form[:retired].first)

      described_class.perform_now(dry_run: false)

      expect(current_definition_id(fp)).to eq(form[:published].id)
    end

    it 'requires an explicit data source when there are several HMIS data sources' do
      other_ds
      expect { described_class.perform_now }.to raise_error(ArgumentError, /exactly one HMIS data source/)
    end
  end
end
