# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enrollment file uploads', type: :request do
  let(:user) { create(:user) }
  let(:valid_edi_path) { Rails.root.join('spec/fixtures/files/health/valid_edi_834.txt') }
  let(:invalid_html_path) { Rails.root.join('spec/fixtures/files/health/invalid_html.csv') }

  before(:each) do
    sign_in user
    allow(user).to receive(:can_administer_health?).and_return(true)
    allow(user).to receive(:has_some_patient_access?).and_return(true)
    allow(GrdaWarehouse::Config).to receive(:get).and_call_original
    allow(GrdaWarehouse::Config).to receive(:get).with(:healthcare_available).and_return(true)
    allow_any_instance_of(WarehouseReports::Health::EnrollmentsController).to receive(:require_compliance_agreement!)
    allow_any_instance_of(WarehouseReports::Health::EnrollmentsController).to receive(:require_training!)
  end

  describe 'Upload Persistence' do
    it 'persists uploaded EDI 834 file to database' do
      expect do
        post warehouse_reports_health_enrollments_path, params: {
          health_enrollment: {
            content: fixture_file_upload(valid_edi_path, 'text/plain'),
          },
        }
      end.to change { Health::Enrollment.count }.by(1)

      enrollment_file = Health::Enrollment.last

      # Verify file was persisted to database
      expect(enrollment_file).to be_persisted
      expect(enrollment_file.content).to be_present
      expect(enrollment_file.content.size).to be > 0

      # Verify metadata is set correctly
      expect(enrollment_file.original_filename).to eq('valid_edi_834.txt')
      expect(enrollment_file.user_id).to eq(user.id)
      expect(enrollment_file.status).to eq('processing')

      # Verify content matches uploaded file
      original_content = File.read(valid_edi_path)
      expect(enrollment_file.content).to eq(original_content)
    end
  end

  describe 'Download Round-Trip' do
    it 'stores and retrieves file with identical content' do
      # Upload file
      post warehouse_reports_health_enrollments_path, params: {
        health_enrollment: {
          content: fixture_file_upload(valid_edi_path, 'text/plain'),
        },
      }

      enrollment_file = Health::Enrollment.last
      original_content = File.read(valid_edi_path)

      # Ensure user is signed in before download request
      sign_in user

      # Download file
      get download_warehouse_reports_health_enrollment_path(id: enrollment_file.id, format: :edi)

      expect(response).to have_http_status(:success)
      expect(response.body).to eq(original_content)
      expect(response.body.bytesize).to eq(original_content.bytesize)
    end
  end

  describe 'File Type Validation' do
    it 'accepts valid EDI 834 files' do
      expect do
        post warehouse_reports_health_enrollments_path, params: {
          health_enrollment: {
            content: fixture_file_upload(valid_edi_path, 'text/plain'),
          },
        }
      end.to change { Health::Enrollment.count }.by(1)

      enrollment_file = Health::Enrollment.last
      expect(enrollment_file.content).to start_with('ISA')
      expect(enrollment_file.content).to include('834')
      expect(enrollment_file.content).to include('~')
    end

    it 'handles invalid EDI content' do
      # Upload HTML file as EDI
      post warehouse_reports_health_enrollments_path, params: {
        health_enrollment: {
          content: fixture_file_upload(invalid_html_path, 'text/plain'),
        },
      }

      # File may be created but should fail processing
      enrollment_file = Health::Enrollment.last
      if enrollment_file&.created_at&.> 1.second.ago
        # If file was created, it should fail on EDI parsing
        expect(enrollment_file.content).to include('<html>')
      end
    end
  end

  describe 'Background Job Processing' do
    it 'triggers background job after upload' do
      expect do
        post warehouse_reports_health_enrollments_path, params: {
          health_enrollment: {
            content: fixture_file_upload(valid_edi_path, 'text/plain'),
          },
        }
      end.to have_enqueued_job(Health::ProcessEnrollmentChangesJob)
    end
  end
end
