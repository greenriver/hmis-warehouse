###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

        # The import is wrapped in AwsCredentialRescue#with_aws_credential_rescue; the bounded
        # reschedule logic itself is covered in spec/jobs/aws_credential_rescue_spec.rb. Here we
        # only assert that this job wires it up: a credential failure is handled gracefully while
        # any other error still propagates.
        context 'when the importer hits an AWS credential failure' do
          # Match the plugin's detection (by class name) without depending on the AWS
          # SDK being loaded: a StandardError subclass named like an STS credential error.
          let(:credential_error_class) do
            stub_const('Aws::STS::Errors::ExpiredTokenException', Class.new(StandardError))
          end
          let(:credential_error) { credential_error_class.new('token expired') }
          let!(:dj_record) { Delayed::Job.create!(handler: 'dummy') }
          let(:job) { described_class.new }

          before do
            allow(job).to receive(:provider_job_id).and_return(dj_record.id)
            allow(importer_instance).to receive(:import!).and_raise(credential_error)
            allow(SignalHandlerPlugin).to receive(:stop_current_worker!)
          end

          it 'reschedules a fresh attempt and stops the worker instead of failing the job' do
            expect do
              expect(job._perform(klass: importer_class_name, options: options)).to eq(true)
            end.to change(Delayed::Job, :count).by(1)
            expect(SignalHandlerPlugin).to have_received(:stop_current_worker!)
          end

          it 'lets non-credential errors propagate (and does not stop the worker)' do
            allow(importer_instance).to receive(:import!).and_raise(StandardError, 'boom')
            expect do
              job._perform(klass: importer_class_name, options: options)
            end.to raise_error('boom')
            expect(SignalHandlerPlugin).not_to have_received(:stop_current_worker!)
          end
        end
      end
    end
  end
end
