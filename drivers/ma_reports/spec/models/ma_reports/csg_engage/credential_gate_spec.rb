###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaReports::CsgEngage::Report, type: :model do
  describe '.run_if_ready' do
    let!(:agency) { create(:csg_engage_agency) }

    def create_credential(active:)
      MaReports::CsgEngage::Credential.create!(
        username: '',
        active: active,
        endpoint: 'https://www.example.com',
        additional_headers: { 'hour' => Time.current.hour },
        slug: 'csg_engage_endpoint',
        password: 'test',
      )
    end

    before do
      stub_request(:any, /https:\/\/www\.example\.com\/.*/).to_return_json(body: { 'ok' => true })
    end

    it 'creates one report per agency when the credential is inactive' do
      create_credential(active: false)

      expect { described_class.run_if_ready }.to change(described_class, :count).by(1)
    end

    it 'creates one report per agency when the credential is active' do
      create_credential(active: true)

      expect { described_class.run_if_ready }.to change(described_class, :count).by(1)
    end

    it 'creates no reports for an active credential in sandbox mode' do
      create_credential(active: true)

      with_sandbox_mode do
        expect { described_class.run_if_ready }.not_to change(described_class, :count)
      end
    end
  end
end

RSpec.describe MaReports::CsgEngage::ProgramReport, type: :model do
  let(:program) { create(:csg_engage_program) }
  let(:program_report) do
    described_class.create!(
      report: create(:csg_engage_report, agency: program.agency),
      program: program,
      imported_program_name: program.csg_engage_name,
      imported_import_keyword: program.csg_engage_import_keyword,
    )
  end

  def create_credential(active:)
    MaReports::CsgEngage::Credential.create!(
      username: '',
      active: active,
      endpoint: 'https://www.example.com',
      slug: 'csg_engage_endpoint',
      password: 'import-key|delete-key',
    )
  end

  before do
    stub_request(:any, /https:\/\/www\.example\.com\/.*/).to_return(body: '{"ok":true}')
  end

  describe '#delete_from_csg' do
    it 'sends the delete request when the credential is inactive' do
      create_credential(active: false)

      expect { program_report.delete_from_csg }.to change { program_report.reload.cleared_at }.from(nil)
      expect(WebMock).to have_requested(:post, /www\.example\.com\/Delete/).once
    end

    it 'raises and sends no request in sandbox mode' do
      create_credential(active: true)

      with_sandbox_mode do
        expect { program_report.delete_from_csg }.to raise_error(ActiveRecord::RecordNotFound)
      end
      expect(WebMock).not_to have_requested(:any, /www\.example\.com/)
      expect(program_report.reload.cleared_at).to be_nil
    end
  end

  describe '#_run' do
    it 'posts the import when the credential is inactive' do
      create_credential(active: false)

      program_report._run

      expect(WebMock).to have_requested(:post, 'https://www.example.com/Import').once
      expect(program_report.reload.raw_result).to eq('{"ok":true}')
    end

    it 'raises and sends no request in sandbox mode' do
      create_credential(active: true)

      with_sandbox_mode do
        expect { program_report._run }.to raise_error(ActiveRecord::RecordNotFound)
      end
      expect(WebMock).not_to have_requested(:any, /www\.example\.com/)
      expect(program_report.reload.raw_result).to be_nil
    end
  end
end
