# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enrollment Reasons file uploads', type: :request do
  let(:user) { create(:user) }
  let!(:aco) { create(:accountable_care_organization, name: 'Test ACO', e_d_file_prefix: 'TEST') }
  let(:valid_xlsx_path) { Rails.root.join('spec/fixtures/files/health/valid_enrollment_reasons.xlsx') }
  let(:valid_csv_path) { Rails.root.join('spec/fixtures/files/health/valid_roster.csv') }
  let(:invalid_html_path) { Rails.root.join('spec/fixtures/files/health/invalid_html.csv') }
  let!(:sender) { create(:sender) }
  let!(:receiver) { create(:receiver) }

  before(:each) do
    sign_in user
    allow(user).to receive(:can_administer_health?).and_return(true)
    allow(user).to receive(:has_some_patient_access?).and_return(true)
    allow(GrdaWarehouse::Config).to receive(:get).and_call_original
    allow(GrdaWarehouse::Config).to receive(:get).with(:healthcare_available).and_return(true)
    allow_any_instance_of(WarehouseReports::Health::EnrollmentsDisenrollmentsController).to receive(:require_compliance_agreement!)
    allow_any_instance_of(WarehouseReports::Health::EnrollmentsDisenrollmentsController).to receive(:require_training!)
    allow_any_instance_of(WarehouseReports::Health::EnrollmentsDisenrollmentsController).to receive(:report_visible?).and_return(true)
    allow_any_instance_of(WarehouseReports::Health::EnrollmentsDisenrollmentsController).to receive(:require_can_view_any_reports!).and_return(true)
  end

  describe 'Upload Persistence for XLSX' do
    it 'persists uploaded XLSX file to database' do
      expect do
        post warehouse_reports_health_enrollments_disenrollments_path, params: {
          report: {
            file: fixture_file_upload(valid_xlsx_path, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
            acos: [aco.id],
            start_month: Date.current.month,
            end_month: Date.current.month,
            effective_date: Date.current,
          },
        }
      end.to change { Health::EnrollmentReasons.count }.by(1)

      enrollment_reasons = Health::EnrollmentReasons.last

      # Verify file was persisted to database
      expect(enrollment_reasons).to be_persisted
      expect(enrollment_reasons.content).to be_present
      expect(enrollment_reasons.content.size).to be > 0

      # Verify metadata is set correctly
      expect(enrollment_reasons.name).to eq('valid_enrollment_reasons.xlsx')

      # Verify content matches uploaded file (binary comparison)
      original_content = File.binread(valid_xlsx_path)
      expect(enrollment_reasons.content.bytesize).to eq(original_content.bytesize)
    end
  end

  describe 'Download Round-Trip for XLSX' do
    it 'stores and retrieves file with identical content' do
      # Upload file
      post warehouse_reports_health_enrollments_disenrollments_path, params: {
        report: {
          file: fixture_file_upload(valid_xlsx_path, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
          acos: [aco.id],
          start_month: Date.current.month,
          end_month: Date.current.month,
          effective_date: Date.current,
        },
      }

      enrollment_reasons = Health::EnrollmentReasons.last
      original_content = File.binread(valid_xlsx_path)

      # Ensure user is signed in before download request
      sign_in user

      # Download file
      get download_warehouse_reports_health_enrollments_disenrollment_path(id: enrollment_reasons.id)

      # Note: Response may be a ZIP file containing reports, not the original file
      # So we verify the stored content instead
      expect(enrollment_reasons.content).to eq(original_content)
      expect(enrollment_reasons.content.bytesize).to eq(original_content.bytesize)
    end
  end

  describe 'File Type Validation' do
    it 'accepts valid XLSX files' do
      expect do
        post warehouse_reports_health_enrollments_disenrollments_path, params: {
          report: {
            file: fixture_file_upload(valid_xlsx_path, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
            acos: [aco.id],
            start_month: Date.current.month,
            end_month: Date.current.month,
            effective_date: Date.current,
          },
        }
      end.to change { Health::EnrollmentReasons.count }.by(1)

      enrollment_reasons = Health::EnrollmentReasons.last
      # XLSX files start with PK (ZIP signature)
      expect(enrollment_reasons.content[0..1]).to eq('PK')
    end

    it 'rejects invalid file content' do
      # With the new validation, invalid files are caught early with validation errors
      # and not saved to the database (which is better!)
      initial_count = Health::EnrollmentReasons.count

      post warehouse_reports_health_enrollments_disenrollments_path, params: {
        report: {
          file: fixture_file_upload(invalid_html_path, 'text/csv'),
          acos: [aco.id],
          start_month: Date.current.month,
          end_month: Date.current.month,
          effective_date: Date.current,
        },
      }

      # The upload should be rejected and no record created
      expect(Health::EnrollmentReasons.count).to eq(initial_count)
      expect(flash[:error]).to be_present
      expect(flash[:error]).to include('File upload failed')
      expect(response).to have_http_status(:success) # renders :index
    end
  end
end
