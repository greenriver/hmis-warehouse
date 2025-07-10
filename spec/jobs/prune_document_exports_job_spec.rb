# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PruneDocumentExportsJob, type: :job do
  describe '#perform' do
    let(:user) { create(:user) }
    let!(:expired_export) do
      create(:hmis_document_export, user: user, created_at: 31.days.ago)
    end
    let!(:recent_export) do
      create(:hmis_document_export, user: user)
    end

    it 'deletes expired document exports' do
      expect { described_class.new.perform }.
        to change(GrdaWarehouse::DocumentExport, :count).by(-1)

      expect(GrdaWarehouse::DocumentExport.find_by(id: recent_export.id)).to be_present
      expect(GrdaWarehouse::DocumentExport.find_by(id: expired_export.id)).to be_nil
    end
  end
end
