# frozen_string_literal: true

RSpec.shared_examples 'paranoid model' do
  it 'soft deletes and restores' do
    record = defined?(build_record) ? instance_exec(&build_record) : raise('define let(:build_record) to use paranoid model shared examples')
    record_id = record.id

    expect(described_class.where(id: record_id)).to exist

    record.destroy

    expect(described_class.where(id: record_id)).not_to exist
    expect(described_class.with_deleted.where(id: record_id)).to exist

    record.restore

    expect(described_class.where(id: record_id)).to exist
  end
end

RSpec.shared_examples 'versioned model' do
  include_context 'with paper trail'

  it 'creates versions on update and destroy' do
    record = defined?(build_record) ? instance_exec(&build_record) : raise('define let(:build_record) to use versioned model shared examples')
    updater = defined?(update_attributes_for_versioning) ? update_attributes_for_versioning : nil
    raise('define let(:update_attributes_for_versioning) to specify an attribute change for versioning') unless updater.respond_to?(:call)

    expect { updater.call(record) }.to change { record.versions.size }.by(1)
    expect { record.destroy }.to change { GrdaWarehouse::Version.where(item_type: record.class.name, item_id: record.id).count }.by(1)
  end
end
