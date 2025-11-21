# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudSpmReport::CellExportJob, type: :job do
  describe '#perform' do
    let(:user) { create(:user) }
    let(:report) do
      create(
        :hud_reports_report_instance,
        user: user,
        report_name: 'System Performance Measures - FY 2026',
        options: { 'report_version' => 'fy2026' },
      )
    end
    let(:job_args) do
      {
        user_id: user.id,
        report_id: report.id,
        measure_id: 'Q1',
        cell_id: 'B2',
        table: 'Measure 1',
      }
    end

    let(:client) do
      instance_double('HudReports::Client', project_id: 42).tap do |c|
        allow(c).to receive(:display_value).and_return('value')
      end
    end
    let(:clients) { [client] }
    let(:policy_context) { instance_double('PolicyContext', preload_project_dependencies: true) }
    let(:pii_policy) { double('PiiPolicy') }
    let(:blob) { instance_double(ActiveStorage::Blob) }
    let(:mailer) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }
    let(:job_user) do
      instance_double(
        User,
        id: user.id,
        name: 'Report User',
        email: 'report@example.com',
        policy_context: policy_context,
        reporting_policy_for_project: pii_policy,
      )
    end

    let(:fake_relation_class) do
      Class.new do
        def initialize(clients)
          @clients = clients
        end

        def joins(*)
          self
        end

        def merge(*)
          self
        end

        def distinct
          self
        end

        def preload(*)
          @clients
        end
      end
    end

    let(:generator_class) do
      relation_class = fake_relation_class
      client_set = clients
      Class.new do
        class << self
          attr_accessor :relation_class, :client_set
        end

        def self.file_prefix
          'SPM FY 2026'
        end

        def self.valid_question_number(question_number)
          question_number
        end

        def self.column_headings(_question)
          { 'first_name' => 'First Name', 'last_name' => 'Last Name' }
        end

        def self.pii_columns
          ['first_name']
        end

        def self.client_scope(_question)
          relation_class.new(client_set)
        end
      end.tap do |klass|
        klass.relation_class = relation_class
        klass.client_set = client_set
      end
    end

    before do
      allow(GrdaWarehouse::Config).to receive(:get).with(:include_pii_in_detail_downloads).and_return(false)
      allow(job_user).to receive(:policy_context).and_return(policy_context)
      allow(job_user).to receive(:reporting_policy_for_project).and_return(pii_policy)
      allow(User).to receive(:find).with(user.id).and_return(job_user)
      allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_return(blob)
      allow(HudSpmReport::Mailer).to receive(:export_ready).and_return(mailer)
      allow_any_instance_of(described_class).to receive(:possible_generator_classes).and_return({ fy2026: generator_class })
    end

    it 'builds the export using the generator class helpers' do
      expect(generator_class).to receive(:valid_question_number).with('Q1').and_call_original
      expect(generator_class).to receive(:client_scope).with('Q1').and_call_original
      expect(generator_class).to receive(:column_headings).with('Q1').and_call_original

      described_class.new.perform(**job_args)

      expect(policy_context).to have_received(:preload_project_dependencies).with([42])
      expect(job_user).to have_received(:reporting_policy_for_project).with(project_id: 42, mode: :download)
      expect(ActiveStorage::Blob).to have_received(:create_and_upload!).with(hash_including(filename: 'SPM FY 2026 Q1 B2.xlsx'))
      expect(HudSpmReport::Mailer).to have_received(:export_ready).with(job_user, blob, 'SPM FY 2026 Q1 B2')
    end
  end
end
