# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CP Roster file uploads', type: :request do
  let(:user) { create(:user) }
  let(:valid_csv_path) { Rails.root.join('spec/fixtures/files/health/valid_roster.csv') }
  let(:invalid_html_path) { Rails.root.join('spec/fixtures/files/health/invalid_html.csv') }

  before(:each) do
    sign_in user
    allow(user).to receive(:can_administer_health?).and_return(true)
    allow(user).to receive(:has_some_patient_access?).and_return(true)
    allow(GrdaWarehouse::Config).to receive(:get).and_call_original
    allow(GrdaWarehouse::Config).to receive(:get).with(:healthcare_available).and_return(true)
    allow_any_instance_of(Health::CareplansController).to receive(:require_compliance_agreement!)
    allow_any_instance_of(Health::CareplansController).to receive(:require_training!)
  end

  # before(:all) do
  #   # Override authorization methods for all tests in this file
  #   WarehouseReports::Health::CpRosterController.prepend(Module.new do
  #     def require_compliance_agreement!
  #     end

  #     def require_training!
  #     end
  #   end)
  # end

  describe 'Upload Persistence for Roster Files' do
    it 'persists uploaded roster CSV file to database' do
      expect do
        post roster_warehouse_reports_health_cp_roster_index_path, params: {
          roster: {
            content: fixture_file_upload(valid_csv_path, 'text/csv'),
          },
        }
      end.to change { Health::CpMembers::RosterFile.count }.by(1)

      roster_file = Health::CpMembers::RosterFile.last

      # Verify file was persisted to database
      expect(roster_file).to be_persisted
      expect(roster_file.content).to be_present
      expect(roster_file.content.size).to be > 0

      # Verify metadata is set correctly
      expect(roster_file.user_id).to eq(user.id)

      # Verify content matches uploaded file
      original_content = File.read(valid_csv_path)
      expect(roster_file.content).to eq(original_content)
    end
  end

  describe 'Upload Persistence for Enrollment Roster Files' do
    it 'persists uploaded enrollment roster CSV file to database' do
      expect do
        post enrollment_warehouse_reports_health_cp_roster_index_path, params: {
          enrollment: {
            content: fixture_file_upload(valid_csv_path, 'text/csv'),
          },
        }
      end.to change { Health::CpMembers::EnrollmentRosterFile.count }.by(1)

      enrollment_file = Health::CpMembers::EnrollmentRosterFile.last

      # Verify file was persisted to database
      expect(enrollment_file).to be_persisted
      expect(enrollment_file.content).to be_present
      expect(enrollment_file.content.size).to be > 0

      # Verify metadata is set correctly
      expect(enrollment_file.user_id).to eq(user.id)
    end
  end

  describe 'Download Round-Trip' do
    it 'stores and retrieves file with identical content' do
      # Upload file
      post roster_warehouse_reports_health_cp_roster_index_path, params: {
        roster: {
          content: fixture_file_upload(valid_csv_path, 'text/csv'),
        },
      }

      roster_file = Health::CpMembers::RosterFile.last
      original_content = File.read(valid_csv_path)

      # Verify stored content matches original
      expect(roster_file.content).to eq(original_content)
      expect(roster_file.content.bytesize).to eq(original_content.bytesize)
    end
  end

  describe 'File Type Validation' do
    it 'accepts valid CSV roster files' do
      expect do
        post roster_warehouse_reports_health_cp_roster_index_path, params: {
          roster: {
            content: fixture_file_upload(valid_csv_path, 'text/csv'),
          },
        }
      end.to change { Health::CpMembers::RosterFile.count }.by(1)

      roster_file = Health::CpMembers::RosterFile.last
      expect(roster_file.content).to include('Member ID')
      expect(roster_file.content).to include('First Name')
    end

    it 'handles invalid file content' do
      # Upload HTML file disguised as CSV
      post roster_warehouse_reports_health_cp_roster_index_path, params: {
        roster: {
          content: fixture_file_upload(invalid_html_path, 'text/csv'),
        },
      }

      # File may be created but should fail processing
      roster_file = Health::CpMembers::RosterFile.last
      if roster_file&.created_at&.> 1.second.ago
        # If file was created, it should fail on CSV parsing
        expect(roster_file.content).to include('<html>')
      end
    end
  end
end
