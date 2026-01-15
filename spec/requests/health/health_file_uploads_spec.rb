# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Health::HealthFile uploads', type: :request do
  let(:user) { create(:user) }
  let(:client) { create(:fixed_destination_client) }
  let(:patient) { create(:patient, client: client) }
  let(:careplan) { create(:careplan, patient: patient, user: user) }

  let(:valid_pdf_path) { Rails.root.join('spec/fixtures/files/health/valid.pdf') }
  let(:invalid_jpeg_path) { Rails.root.join('spec/fixtures/files/health/invalid_jpeg.pdf') }

  before(:each) do
    sign_in user
    allow(user).to receive(:can_administer_health?).and_return(true)
    allow(user).to receive(:has_some_patient_access?).and_return(true)
    allow(GrdaWarehouse::Config).to receive(:get).and_call_original
    allow(GrdaWarehouse::Config).to receive(:get).with(:healthcare_available).and_return(true)
    allow_any_instance_of(Health::CareplansController).to receive(:require_compliance_agreement!)
    allow_any_instance_of(Health::CareplansController).to receive(:require_training!)
  end

  describe 'Upload Persistence' do
    it 'persists uploaded PDF file to database' do
      expect do
        patch upload_client_health_careplan_path(client_id: client.id, id: careplan.id), params: {
          health_file: {
            health_file_attributes: {
              file: fixture_file_upload(valid_pdf_path, 'application/pdf'),
            },
          },
        }
      end.to change { Health::HealthFile.count }.by(1)

      health_file = Health::HealthFile.last

      # Verify file was persisted to database
      expect(health_file).to be_persisted
      expect(health_file.content).to be_present
      expect(health_file.content.size).to be > 0

      # Verify metadata is set correctly
      expect(health_file.name).to eq('valid.pdf')
      expect(health_file.size).to eq(File.size(valid_pdf_path))
      expect(health_file.content_type).to eq('application/pdf')
      expect(health_file.user_id).to eq(user.id)
      expect(health_file.client_id).to eq(client.id)
    end
  end

  describe 'Download Round-Trip' do
    it 'downloads file with identical content to uploaded file' do
      # Create fresh careplan for this test
      test_careplan = create(:careplan, patient: patient, user: user)

      # Upload file
      patch upload_client_health_careplan_path(client_id: client.id, id: test_careplan.id), params: {
        health_file: {
          health_file_attributes: {
            file: fixture_file_upload(valid_pdf_path, 'application/pdf'),
          },
        },
      }

      test_careplan.reload
      original_content = File.binread(valid_pdf_path)

      # Ensure user is signed in before download request
      sign_in user

      # Download file
      get download_client_health_careplan_path(client_id: client.id, id: test_careplan.id)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/pdf')
      expect(response.body).to eq(original_content)
      expect(response.body.bytesize).to eq(original_content.bytesize)
    end
  end

  describe 'File Type Validation' do
    it 'accepts valid PDF files' do
      expect do
        patch upload_client_health_careplan_path(client_id: client.id, id: careplan.id), params: {
          health_file: {
            health_file_attributes: {
              file: fixture_file_upload(valid_pdf_path, 'application/pdf'),
            },
          },
        }
      end.to change { Health::HealthFile.count }.by(1)

      health_file = Health::HealthFile.last
      expect(health_file.content_type).to eq('application/pdf')
    end

    it 'rejects JPEG files with PDF extension' do
      expect do
        patch upload_client_health_careplan_path(client_id: client.id, id: careplan.id), params: {
          health_file: {
            health_file_attributes: {
              file: fixture_file_upload(invalid_jpeg_path, 'application/pdf'),
            },
          },
        }
      end.not_to(change { Health::HealthFile.count })

      # After migration, files with invalid content are properly validated and rejected
      # The upload should fail validation
      careplan.reload
      expect(careplan.health_file).to be_nil
    end
  end

  describe 'Size Limit' do
    it 'validates file size is within limit' do
      # Create a file slightly under 25MB
      large_content = "%PDF-1.4\n" + ('A' * (24 * 1024 * 1024)) + "\n%%EOF"
      large_file = Tempfile.new(['large', '.pdf'])
      large_file.binmode
      large_file.write(large_content)
      large_file.rewind

      patch upload_client_health_careplan_path(client_id: client.id, id: careplan.id), params: {
        health_file: {
          health_file_attributes: {
            file: fixture_file_upload(large_file.path, 'application/pdf'),
          },
        },
      }

      # Should succeed (under limit)
      health_file = Health::HealthFile.last
      expect(health_file).to be_present
      expect(health_file.size).to be <= 25.megabytes

      large_file.close
      large_file.unlink
    end
  end
end
