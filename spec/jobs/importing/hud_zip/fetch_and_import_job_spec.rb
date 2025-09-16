# frozen_string_literal: true

require 'rails_helper'

module Importing
  module HudZip
    RSpec.describe FetchAndImportJob, type: :job do
      describe '#_perform' do
        let(:data_source) { create(:grda_warehouse_data_source) }
        let(:options) { { data_source_id: data_source.id, region: 'x', bucket_name: 'x', path: 'x' } }
        let(:importer_class_name) { 'Importers::HmisAutoMigrate::S3' }
        let(:importer_class) { class_double(importer_class_name).as_stubbed_const }
        let(:importer_instance) { instance_double(importer_class_name) }

        before do
          allow(importer_class).to receive(:new).with(options).and_return(importer_instance)
          allow(importer_instance).to receive(:import!)
        end

        it 'calls the importer' do
          described_class.new._perform(klass: importer_class_name, options: options)
          expect(importer_instance).to have_received(:import!)
        end
      end
    end
  end
end
