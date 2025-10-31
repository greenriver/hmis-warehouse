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
    raise('define let(:build_record) to use versioned model shared examples') unless defined?(build_record)

    record = instance_exec(&build_record)
    updater = update_attributes_for_versioning if defined?(update_attributes_for_versioning)
    raise('define let(:update_attributes_for_versioning) to specify an attribute change for versioning') unless updater.respond_to?(:call)

    expect { updater.call(record) }.to change { record.versions.size }.by(1)
    # Use the association to avoid STI/base-class item_type mismatches
    expect { record.destroy }.to change { record.versions.size }.by(1)
  end
end

RSpec.shared_examples 'enrollment related versioned model' do
  # Include the base versioned model behavior
  it_behaves_like 'versioned model'

  describe 'version metadata' do
    include_context 'with paper trail'

    it 'stores enrollment_id, client_id, and project_id in version metadata' do
      raise('define let(:build_record) to use enrollment related versioned model shared examples') unless defined?(build_record)

      record = instance_exec(&build_record)

      version = record.versions.order(:id).last
      expect(version.enrollment_id).to eq(record.enrollment.id)
      expect(version.client_id).to eq(record.client.id)
      expect(version.project_id).to eq(record.project.id)
    end
  end
end
