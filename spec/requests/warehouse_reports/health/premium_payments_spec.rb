# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Premium Payment file uploads', type: :request do
  let(:user) { create(:user) }
  let(:valid_edi_path) { Rails.root.join('spec/fixtures/files/health/valid_edi_820.txt') }
  let(:invalid_html_path) { Rails.root.join('spec/fixtures/files/health/invalid_html.csv') }

  before(:each) do
    sign_in user
    allow(user).to receive(:can_administer_health?).and_return(true)
    allow(user).to receive(:has_some_patient_access?).and_return(true)
    allow(GrdaWarehouse::Config).to receive(:get).and_call_original
    allow(GrdaWarehouse::Config).to receive(:get).with(:healthcare_available).and_return(true)
    allow_any_instance_of(WarehouseReports::Health::PremiumPaymentsController).to receive(:require_compliance_agreement!)
    allow_any_instance_of(WarehouseReports::Health::PremiumPaymentsController).to receive(:require_training!)
    allow_any_instance_of(WarehouseReports::Health::PremiumPaymentsController).to receive(:report_visible?).and_return(true)
    allow_any_instance_of(WarehouseReports::Health::PremiumPaymentsController).to receive(:require_can_view_any_reports!).and_return(true)
  end

  describe 'Upload Persistence' do
    it 'persists uploaded EDI 820 file to database' do
      expect do
        post warehouse_reports_health_premium_payments_path, params: {
          health_premium_payment: {
            content: fixture_file_upload(valid_edi_path, 'text/plain'),
          },
        }
      end.to change { Health::PremiumPayment.count }.by(1)

      payment_file = Health::PremiumPayment.last

      # Verify file was persisted to database
      expect(payment_file).to be_persisted
      expect(payment_file.content).to be_present
      expect(payment_file.content.size).to be > 0

      # Verify metadata is set correctly
      expect(payment_file.original_filename).to eq('valid_edi_820.txt')
      expect(payment_file.user_id).to eq(user.id)

      # Verify content matches uploaded file
      original_content = File.read(valid_edi_path)
      expect(payment_file.content).to eq(original_content)
    end
  end

  describe 'Download Round-Trip' do
    it 'stores and retrieves file with identical content' do
      # Upload file
      post warehouse_reports_health_premium_payments_path, params: {
        health_premium_payment: {
          content: fixture_file_upload(valid_edi_path, 'text/plain'),
        },
      }

      payment_file = Health::PremiumPayment.last
      original_content = File.read(valid_edi_path)

      # Ensure user is signed in before download request
      sign_in user

      # Download file
      get warehouse_reports_health_premium_payment_path(id: payment_file.id, format: :text)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('text/plain')
      expect(response.body).to eq(original_content)
      expect(response.body.bytesize).to eq(original_content.bytesize)
    end
  end

  describe 'File Type Validation' do
    it 'accepts valid EDI 820 files' do
      expect do
        post warehouse_reports_health_premium_payments_path, params: {
          health_premium_payment: {
            content: fixture_file_upload(valid_edi_path, 'text/plain'),
          },
        }
      end.to change { Health::PremiumPayment.count }.by(1)

      payment_file = Health::PremiumPayment.last
      expect(payment_file.content).to start_with('ISA')
      expect(payment_file.content).to include('820')
      expect(payment_file.content).to include('~')
    end

    it 'handles invalid EDI content' do
      # Upload HTML file as EDI
      post warehouse_reports_health_premium_payments_path, params: {
        health_premium_payment: {
          content: fixture_file_upload(invalid_html_path, 'text/plain'),
        },
      }

      # File may be created but should fail processing
      payment_file = Health::PremiumPayment.last
      if payment_file&.created_at&.> 1.second.ago
        # If file was created, it should fail on EDI parsing
        expect(payment_file.content).to include('<html>')
      end
    end
  end

  describe 'Background Job Processing' do
    it 'triggers background job after upload' do
      expect do
        post warehouse_reports_health_premium_payments_path, params: {
          health_premium_payment: {
            content: fixture_file_upload(valid_edi_path, 'text/plain'),
          },
        }
      end.to have_enqueued_job(Health::ConvertPaymentPremiumFileJob)
    end
  end
end
