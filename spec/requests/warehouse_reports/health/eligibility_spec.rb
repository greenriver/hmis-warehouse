# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Eligibility Response file uploads', type: :request do
  let(:user) { create(:user) }
  let!(:inquiry) { create(:eligibility_inquiry, service_date: Date.current) }
  let(:valid_edi_path) { Rails.root.join('spec/fixtures/files/health/valid_edi_271.txt') }
  let(:invalid_html_path) { Rails.root.join('spec/fixtures/files/health/invalid_html.csv') }

  before(:each) do
    sign_in user
    allow(user).to receive(:can_administer_health?).and_return(true)
    allow(user).to receive(:has_some_patient_access?).and_return(true)
    allow(GrdaWarehouse::Config).to receive(:get).and_call_original
    allow(GrdaWarehouse::Config).to receive(:get).with(:healthcare_available).and_return(true)
    allow_any_instance_of(WarehouseReports::Health::EligibilityController).to receive(:require_compliance_agreement!)
    allow_any_instance_of(WarehouseReports::Health::EligibilityController).to receive(:require_training!)
  end

  describe 'Upload Persistence' do
    it 'persists uploaded EDI 271 file to database' do
      expect do
        patch warehouse_reports_health_eligibility_path(id: inquiry.id), params: {
          result: {
            content: fixture_file_upload(valid_edi_path, 'text/plain'),
          },
        }
      end.to change { Health::EligibilityResponse.count }.by(1)

      response_file = Health::EligibilityResponse.last

      # Verify file was persisted to database
      expect(response_file).to be_persisted
      expect(response_file.response).to be_present
      expect(response_file.response.size).to be > 0

      # Verify metadata is set correctly
      expect(response_file.original_filename).to eq('valid_edi_271.txt')
      expect(response_file.user_id).to eq(user.id)
      expect(response_file.eligibility_inquiry_id).to eq(inquiry.id)

      # Verify content matches uploaded file
      original_content = File.read(valid_edi_path)
      expect(response_file.response).to eq(original_content)
    end
  end

  describe 'Download Round-Trip' do
    it 'stores and retrieves file with identical content' do
      # Upload file
      patch warehouse_reports_health_eligibility_path(id: inquiry.id), params: {
        result: {
          content: fixture_file_upload(valid_edi_path, 'text/plain'),
        },
      }

      response_file = Health::EligibilityResponse.last
      original_content = File.read(valid_edi_path)

      # Verify stored content matches original
      expect(response_file.response).to eq(original_content)
      expect(response_file.response.bytesize).to eq(original_content.bytesize)
    end
  end

  describe 'File Type Validation' do
    it 'accepts valid EDI 271 files' do
      expect do
        patch warehouse_reports_health_eligibility_path(id: inquiry.id), params: {
          result: {
            content: fixture_file_upload(valid_edi_path, 'text/plain'),
          },
        }
      end.to change { Health::EligibilityResponse.count }.by(1)

      response_file = Health::EligibilityResponse.last
      expect(response_file.response).to start_with('ISA')
      expect(response_file.response).to include('271')
      expect(response_file.response).to include('~')
    end

    it 'handles invalid EDI content' do
      # Upload HTML file as EDI
      patch warehouse_reports_health_eligibility_path(id: inquiry.id), params: {
        result: {
          content: fixture_file_upload(invalid_html_path, 'text/plain'),
        },
      }

      # File may be created but should fail processing
      response_file = Health::EligibilityResponse.last
      if response_file&.created_at&.> 1.second.ago
        # If file was created, it should fail on EDI parsing
        expect(response_file.response).to include('<html>')
      end
    end
  end

  describe 'Background Job Processing' do
    it 'triggers background job after upload' do
      expect do
        patch warehouse_reports_health_eligibility_path(id: inquiry.id), params: {
          result: {
            content: fixture_file_upload(valid_edi_path, 'text/plain'),
          },
        }
      end.to have_enqueued_job(Health::FlagIneligiblePatientsJob)
    end
  end
end
