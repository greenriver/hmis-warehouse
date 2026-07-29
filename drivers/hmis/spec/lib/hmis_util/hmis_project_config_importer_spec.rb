###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe HmisUtil::HmisProjectConfigImporter do
  let!(:data_source) { create(:hmis_data_source) }
  let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectID: 'P1') }
  let!(:sending_project) { create(:hmis_hud_project, data_source: data_source, ProjectID: 'SEND1') }
  let!(:sending_project_2) { create(:hmis_hud_project, data_source: data_source, ProjectID: 'SEND2') }

  def write_csv(headers, rows)
    file = Tempfile.new(['project_configs', '.csv'])
    CSV.open(file.path, 'w') do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
    file
  end

  def run_import!(csv_file, dry_run: false, data_source_id: data_source.id, skip_projects_not_found: false)
    described_class.new(
      csv_path: csv_file.path,
      data_source_id: data_source_id,
      dry_run: dry_run,
      skip_projects_not_found: skip_projects_not_found,
    ).run!
  end

  def rebuild_candidate_pool_callback_count
    Hmis::ProjectCeConfig._save_callbacks.count { |cb| cb.filter == :rebuild_candidate_pool }
  end

  after { csv_file&.close! }

  let(:csv_file) { nil }

  describe 'full CSV create' do
    let(:headers) do
      [
        'ProjectID',
        'AutoExit',
        'AutoExitDays',
        'AutoEnter',
        'CE_SendsReferrals',
        'CE_ReceivesDirectReferrals',
        'CE_ReceivesDirectReferralsFrom_ProjectIDs',
        'CE_SupportsWaitlists',
      ]
    end
    let(:csv_file) do
      write_csv(headers, [['P1', 'true', '45', 'true', 'true', 'true', 'SEND1, SEND2', 'true']])
    end

    it 'creates all config types' do
      expect { run_import!(csv_file) }.to change(Hmis::ProjectConfig, :count).by(4)

      auto_exit = Hmis::ProjectAutoExitConfig.find_by!(project: project)
      expect(auto_exit.length_of_absence_days).to eq(45)
      expect(auto_exit.enabled).to eq(true)
      expect(auto_exit.data_source_id).to eq(data_source.id)

      expect(Hmis::ProjectAutoEnterConfig.find_by!(project: project)).to be_present
      expect(Hmis::ProjectSendsDirectCeReferralsConfig.find_by!(project: project)).to be_present

      ce = Hmis::ProjectCeConfig.find_by!(project: project)
      expect(ce.receives_direct_referrals?).to eq(true)
      expect(ce.supports_waitlist_referrals?).to eq(true)
      expect(ce.receives_direct_referrals_from).to contain_exactly(sending_project.id, sending_project_2.id)
    end

    it 'is idempotent on a second run' do
      run_import!(csv_file)
      expect { run_import!(csv_file) }.not_to change(Hmis::ProjectConfig, :count)
      expect(Hmis::ProjectAutoExitConfig.find_by!(project: project).length_of_absence_days).to eq(45)
    end
  end

  describe 'partial headers' do
    let(:csv_file) do
      write_csv(['ProjectID', 'AutoEnter'], [['P1', 'true']])
    end

    it 'only creates listed config types' do
      expect { run_import!(csv_file) }.to change(Hmis::ProjectConfig, :count).by(1)
      expect(Hmis::ProjectAutoEnterConfig.find_by(project: project)).to be_present
      expect(Hmis::ProjectAutoExitConfig.find_by(project: project)).to be_nil
      expect(Hmis::ProjectCeConfig.find_by(project: project)).to be_nil
    end
  end

  describe 'AutoExit / AutoExitDays dependency' do
    it 'errors when AutoExit is present without AutoExitDays' do
      file = write_csv(['ProjectID', 'AutoExit'], [['P1', 'true']])
      expect { run_import!(file) }.to raise_error(HmisUtil::HmisProjectConfigImporter::ImportError, /AutoExit and AutoExitDays/)
      expect(Hmis::ProjectConfig.count).to eq(0)
    ensure
      file.close!
    end

    it 'errors when AutoExitDays is present without AutoExit' do
      file = write_csv(['ProjectID', 'AutoExitDays'], [['P1', '45']])
      expect { run_import!(file) }.to raise_error(HmisUtil::HmisProjectConfigImporter::ImportError, /AutoExit and AutoExitDays/)
    ensure
      file.close!
    end

    it 'errors when AutoExit is true but AutoExitDays is blank' do
      file = write_csv(['ProjectID', 'AutoExit', 'AutoExitDays'], [['P1', 'true', '']])
      expect { run_import!(file) }.to raise_error(HmisUtil::HmisProjectConfigImporter::ImportError, /1 error/)
      expect(Hmis::ProjectConfig.count).to eq(0)
    ensure
      file.close!
    end

    it 'reports model validation errors on dry run when AutoExitDays is below 30' do
      file = write_csv(['ProjectID', 'AutoExit', 'AutoExitDays'], [['P1', 'true', '20']])
      expect { run_import!(file, dry_run: true) }.to raise_error(HmisUtil::HmisProjectConfigImporter::ImportError, /1 error/)
      expect(Hmis::ProjectConfig.count).to eq(0)
    ensure
      file.close!
    end
  end

  describe 'validation errors' do
    it 'errors when ProjectID is not found and makes no changes' do
      file = write_csv(['ProjectID', 'AutoEnter'], [['MISSING', 'true']])
      expect { run_import!(file) }.to raise_error(HmisUtil::HmisProjectConfigImporter::ImportError, /1 error/)
      expect(Hmis::ProjectConfig.count).to eq(0)
    ensure
      file.close!
    end

    it 'skips missing ProjectIDs when skip_projects_not_found is true and continues with other rows' do
      file = write_csv(['ProjectID', 'AutoEnter'], [['MISSING', 'true'], ['P1', 'true']])
      expect { run_import!(file, skip_projects_not_found: true) }.to change(Hmis::ProjectAutoEnterConfig, :count).by(1)
      expect(Hmis::ProjectAutoEnterConfig.find_by(project: project)).to be_present
    ensure
      file.close!
    end

    it 'errors when CE from-ProjectIDs are unknown' do
      file = write_csv(
        ['ProjectID', 'CE_ReceivesDirectReferrals', 'CE_ReceivesDirectReferralsFrom_ProjectIDs'],
        [['P1', 'true', 'NOPE']],
      )
      expect { run_import!(file) }.to raise_error(HmisUtil::HmisProjectConfigImporter::ImportError, /1 error/)
      expect(Hmis::ProjectConfig.count).to eq(0)
    ensure
      file.close!
    end

    it 'errors on duplicate ProjectIDs' do
      file = write_csv(['ProjectID', 'AutoEnter'], [['P1', 'true'], ['P1', 'true']])
      expect { run_import!(file) }.to raise_error(HmisUtil::HmisProjectConfigImporter::ImportError, /1 error/)
    ensure
      file.close!
    end

    it 'scopes ProjectID lookup to the given data source' do
      other_ds = create(:hmis_data_source)
      create(:hmis_hud_project, data_source: other_ds, ProjectID: 'OTHER1')

      file = write_csv(['ProjectID', 'AutoEnter'], [['OTHER1', 'true']])
      expect { run_import!(file) }.to raise_error(HmisUtil::HmisProjectConfigImporter::ImportError, /1 error/)
      expect(Hmis::ProjectConfig.count).to eq(0)
    ensure
      file.close!
    end
  end

  describe 'updates existing configs' do
    let!(:auto_exit) do
      create(:hmis_project_auto_exit_config, project: project, length_of_absence_days: 30)
    end
    let!(:ce) do
      create(
        :hmis_project_ce_config,
        project: project,
        receives_direct_referrals: false,
        supports_waitlist_referrals: true,
      )
    end

    it 'updates AutoExit days and CE flags instead of creating duplicates' do
      file = write_csv(
        ['ProjectID', 'AutoExit', 'AutoExitDays', 'CE_ReceivesDirectReferrals', 'CE_SupportsWaitlists', 'CE_ReceivesDirectReferralsFrom_ProjectIDs'],
        [['P1', 'true', '60', 'true', 'false', 'SEND1']],
      )

      expect { run_import!(file) }.not_to change(Hmis::ProjectConfig, :count)

      expect(auto_exit.reload.length_of_absence_days).to eq(60)
      ce.reload
      expect(ce.receives_direct_referrals?).to eq(true)
      expect(ce.supports_waitlist_referrals?).to eq(false)
      expect(ce.receives_direct_referrals_from).to eq([sending_project.id])
    ensure
      file.close!
    end

    it 'clears receives_direct_referrals_from when From header is blank' do
      ce.receives_direct_referrals = true
      ce.supports_waitlist_referrals = false
      ce.receives_direct_referrals_from = [sending_project.id]
      ce.save!

      file = write_csv(
        ['ProjectID', 'CE_ReceivesDirectReferrals', 'CE_ReceivesDirectReferralsFrom_ProjectIDs'],
        [['P1', 'true', '']],
      )

      run_import!(file)
      expect(ce.reload.receives_direct_referrals_from).to be_nil
    ensure
      file.close!
    end
  end

  describe 'candidate pool rebuild' do
    before do
      allow(Hmis::Ce::Match::CandidatePool).to receive(:lock_for_maintenance!).and_yield
      allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    end

    it 'rebuilds candidate pools once after import when waitlist CE configs exist' do
      other = create(:hmis_hud_project, data_source: data_source, ProjectID: 'P2')
      file = write_csv(
        ['ProjectID', 'CE_SupportsWaitlists'],
        [['P1', 'true'], [other.ProjectID.to_s, 'true']],
      )

      expect { run_import!(file) }.not_to(change { rebuild_candidate_pool_callback_count })
      expect(Hmis::Ce::Match::CandidatePoolBuilder).to have_received(:call).once
    ensure
      file.close!
    end

    it 'does not rebuild candidate pools on dry run' do
      file = write_csv(['ProjectID', 'CE_SupportsWaitlists'], [['P1', 'true']])
      expect { run_import!(file, dry_run: true) }.not_to(change { rebuild_candidate_pool_callback_count })
      expect(Hmis::Ce::Match::CandidatePoolBuilder).not_to have_received(:call)
    ensure
      file.close!
    end

    it 'restores the rebuild_candidate_pool callback when apply raises' do
      create(:hmis_hud_project, data_source: data_source, ProjectID: 'P2')
      file = write_csv(['ProjectID', 'AutoEnter'], [['P1', 'true'], ['P2', 'true']])

      allow_any_instance_of(Hmis::ProjectAutoEnterConfig).to receive(:save!).and_wrap_original do |method, *args|
        record = method.receiver
        raise ActiveRecord::RecordInvalid, record if record.project.ProjectID.to_s == 'P2'

        method.call(*args)
      end

      expect do
        expect { run_import!(file) }.to raise_error(ActiveRecord::RecordInvalid)
      end.not_to(change { rebuild_candidate_pool_callback_count })
    ensure
      file.close!
    end
  end

  describe 'boolean parsing' do
    it 'accepts yes as true' do
      file = write_csv(['ProjectID', 'AutoEnter'], [['P1', 'yes']])
      expect { run_import!(file) }.to change(Hmis::ProjectAutoEnterConfig, :count).by(1)
    ensure
      file.close!
    end

    it 'accepts no as false and skips creating the config' do
      file = write_csv(['ProjectID', 'AutoEnter'], [['P1', 'no']])
      expect { run_import!(file) }.not_to change(Hmis::ProjectConfig, :count)
    ensure
      file.close!
    end
  end

  describe 'false flags' do
    let!(:auto_enter) { create(:hmis_project_auto_enter_config, project: project) }

    it 'skips false flags and leaves existing configs alone' do
      file = write_csv(['ProjectID', 'AutoEnter'], [['P1', 'false']])
      expect { run_import!(file) }.not_to change(Hmis::ProjectConfig, :count)
      expect(auto_enter.reload).to be_present
      expect(auto_enter.enabled).to eq(true)
    ensure
      file.close!
    end
  end

  describe 'dry run' do
    it 'reports would-be creates without writing' do
      file = write_csv(['ProjectID', 'AutoEnter'], [['P1', 'true']])
      expect { run_import!(file, dry_run: true) }.not_to change(Hmis::ProjectConfig, :count)
    ensure
      file.close!
    end

    it 'reports would-be updates without writing' do
      create(:hmis_project_auto_exit_config, project: project, length_of_absence_days: 30)
      file = write_csv(['ProjectID', 'AutoExit', 'AutoExitDays'], [['P1', 'true', '90']])

      expect { run_import!(file, dry_run: true) }.not_to change(Hmis::ProjectConfig, :count)
      expect(Hmis::ProjectAutoExitConfig.find_by!(project: project).length_of_absence_days).to eq(30)
    ensure
      file.close!
    end
  end

  describe 'transaction rollback' do
    it 'rolls back all changes when a save fails mid-import' do
      create(:hmis_hud_project, data_source: data_source, ProjectID: 'P2')
      file = write_csv(['ProjectID', 'AutoEnter'], [['P1', 'true'], ['P2', 'true']])

      allow_any_instance_of(Hmis::ProjectAutoEnterConfig).to receive(:save!).and_wrap_original do |method, *args|
        record = method.receiver
        raise ActiveRecord::RecordInvalid, record if record.project.ProjectID.to_s == 'P2'

        method.call(*args)
      end

      expect { run_import!(file) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Hmis::ProjectAutoEnterConfig.count).to eq(0)
    ensure
      file.close!
    end
  end

  describe 'data source resolution' do
    it 'errors when provided data source is not HMIS' do
      non_hmis = create(:source_data_source)
      file = write_csv(['ProjectID', 'AutoEnter'], [['P1', 'true']])
      expect do
        run_import!(file, data_source_id: non_hmis.id)
      end.to raise_error(HmisUtil::HmisProjectConfigImporter::ImportError, /not an HMIS data source/)
    ensure
      file.close!
    end

    it 'infers the sole HMIS data source when id is omitted' do
      # Ensure this is the only HMIS data source in the DB for this example
      GrdaWarehouse::DataSource.hmis.where.not(id: data_source.id).delete_all

      file = write_csv(['ProjectID', 'AutoEnter'], [['P1', 'true']])
      described_class.new(csv_path: file.path, dry_run: false).run!
      expect(Hmis::ProjectAutoEnterConfig.find_by(project: project)).to be_present
    ensure
      file.close!
    end

    it 'errors when multiple HMIS data sources exist and id is omitted' do
      create(:hmis_data_source)
      file = write_csv(['ProjectID', 'AutoEnter'], [['P1', 'true']])
      expect do
        described_class.new(csv_path: file.path, dry_run: false).run!
      end.to raise_error(HmisUtil::HmisProjectConfigImporter::ImportError, /exactly one HMIS data source/)
    ensure
      file.close!
    end
  end
end
