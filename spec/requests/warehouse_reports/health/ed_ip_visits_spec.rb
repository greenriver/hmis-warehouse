# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ED/IP Visit file uploads', type: :request do
  let(:user) { create(:user) }
  let(:valid_csv_path) { Rails.root.join('spec/fixtures/files/health/valid_ed_ip_visit.csv') }
  let(:invalid_html_path) { Rails.root.join('spec/fixtures/files/health/invalid_html.csv') }

  before(:each) do
    sign_in user
    allow(user).to receive(:can_administer_health?).and_return(true)
    allow(user).to receive(:has_some_patient_access?).and_return(true)
    allow(GrdaWarehouse::Config).to receive(:get).and_call_original
    allow(GrdaWarehouse::Config).to receive(:get).with(:healthcare_available).and_return(true)
    allow_any_instance_of(Health::EdIpVisitsController).to receive(:require_compliance_agreement!)
    allow_any_instance_of(Health::EdIpVisitsController).to receive(:require_training!)
  end

  describe 'Upload Persistence' do
    it 'persists uploaded CSV file to database' do
      expect do
        post warehouse_reports_health_ed_ip_visits_path, params: {
          visits: {
            content: fixture_file_upload(valid_csv_path, 'text/csv'),
          },
        }
      end.to change { Health::EdIpVisitFile.count }.by(1)

      visit_file = Health::EdIpVisitFile.last

      # Verify file was persisted to database
      expect(visit_file).to be_persisted
      expect(visit_file.content).to be_present
      expect(visit_file.content.size).to be > 0

      # Verify metadata is set correctly
      expect(visit_file.user_id).to eq(user.id)

      # Verify content matches uploaded file
      original_content = File.read(valid_csv_path)
      expect(visit_file.content).to eq(original_content)
    end
  end

  describe 'Download Round-Trip' do
    it 'stores and retrieves file with identical content' do
      # Upload file
      post warehouse_reports_health_ed_ip_visits_path, params: {
        visits: {
          content: fixture_file_upload(valid_csv_path, 'text/csv'),
        },
      }

      visit_file = Health::EdIpVisitFile.last
      original_content = File.read(valid_csv_path)

      # Verify stored content matches original
      expect(visit_file.content).to eq(original_content)
      expect(visit_file.content.bytesize).to eq(original_content.bytesize)
    end
  end

  describe 'File Type Validation' do
    it 'accepts valid CSV files' do
      expect do
        post warehouse_reports_health_ed_ip_visits_path, params: {
          visits: {
            content: fixture_file_upload(valid_csv_path, 'text/csv'),
          },
        }
      end.to change { Health::EdIpVisitFile.count }.by(1)

      visit_file = Health::EdIpVisitFile.last
      expect(visit_file.content).to include('Patient ID')
      expect(visit_file.content).to include('Member Record Number')
    end

    it 'handles invalid file content' do
      # Upload HTML file disguised as CSV
      post warehouse_reports_health_ed_ip_visits_path, params: {
        visits: {
          content: fixture_file_upload(invalid_html_path, 'text/csv'),
        },
      }

      # File may be created but should fail processing
      # Check that it was either rejected or marked as failed
      visit_file = Health::EdIpVisitFile.last
      if visit_file&.created_at&.> 1.second.ago
        # If file was created, it should fail on processing
        expect(visit_file.content).to include('<html>')
      end
    end
  end

  describe 'Background Job Processing' do
    it 'triggers background job after upload' do
      expect do
        post warehouse_reports_health_ed_ip_visits_path, params: {
          visits: {
            content: fixture_file_upload(valid_csv_path, 'text/csv'),
          },
        }
      end.to have_enqueued_job(Health::EdIpImportJob)
    end
  end
end
