###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisUtil::BedNightBackfill do
  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:project) { create(:hud_project, data_source: data_source, ProjectType: 1) }
  let!(:client) { create(:hud_client, data_source_id: data_source.id, PersonalID: 'C1') }
  let(:today) { Date.new(2026, 9, 12) }

  def run!(project_pks: [project.id], dry_run: false, **opts)
    described_class.new(project_pks: project_pks, dry_run: dry_run, today: today, **opts).run!
  end

  def create_enrollment(entry_date:, exit_date: nil, project: self.project, client: self.client, user_id: 'U1')
    enrollment = create(
      :hud_enrollment,
      data_source_id: data_source.id,
      ProjectID: project.ProjectID,
      PersonalID: client.PersonalID,
      EntryDate: entry_date,
      UserID: user_id,
    )
    if exit_date
      create(:hud_exit, data_source_id: data_source.id, EnrollmentID: enrollment.EnrollmentID,
                        PersonalID: client.PersonalID, ExitDate: exit_date)
    end
    enrollment
  end

  def create_bed_night(enrollment, date, record_type: 200, type_provided: 200)
    create(
      :hud_service,
      data_source_id: data_source.id,
      EnrollmentID: enrollment.EnrollmentID,
      PersonalID: enrollment.PersonalID,
      DateProvided: date,
      RecordType: record_type,
      TypeProvided: type_provided,
    )
  end

  def bed_night_dates(enrollment)
    GrdaWarehouse::Hud::Service.bed_night.where(data_source_id: data_source.id, EnrollmentID: enrollment.EnrollmentID).pluck(:DateProvided)
  end

  describe 'an exited enrollment' do
    let!(:enrollment) { create_enrollment(entry_date: Date.new(2026, 3, 1), exit_date: Date.new(2026, 3, 4)) }

    it 'inserts one bed night per night from EntryDate through the night before ExitDate' do
      run!
      expect(bed_night_dates(enrollment)).to contain_exactly(Date.new(2026, 3, 1), Date.new(2026, 3, 2), Date.new(2026, 3, 3))
    end

    it 'stamps HUD bed-night type codes, the data source, and the enrollment UserID' do
      run!
      service = GrdaWarehouse::Hud::Service.bed_night.find_by!(EnrollmentID: enrollment.EnrollmentID, DateProvided: Date.new(2026, 3, 2))
      expect(service).to have_attributes(
        RecordType: 200,
        TypeProvided: 200,
        PersonalID: client.PersonalID,
        data_source_id: data_source.id,
        UserID: 'U1',
      )
      expect(service.ServicesID).to match(/\A\h{32}\z/)
      expect(service.DateCreated).to be_within(1.minute).of(Time.current)
      expect(service.DateUpdated).to be_within(1.minute).of(Time.current)
    end
  end

  describe 'an open enrollment' do
    let!(:enrollment) { create_enrollment(entry_date: today - 2.days) }

    it 'inserts nights through yesterday and none for today' do
      run!
      expect(bed_night_dates(enrollment)).to contain_exactly(today - 2.days, today - 1.day)
    end
  end

  describe 'an enrollment that enters and exits on the same day' do
    let!(:enrollment) { create_enrollment(entry_date: Date.new(2026, 3, 1), exit_date: Date.new(2026, 3, 1)) }

    it 'inserts nothing' do
      run!
      expect(bed_night_dates(enrollment)).to be_empty
    end
  end

  describe 'an enrollment that entered today' do
    let!(:enrollment) { create_enrollment(entry_date: today) }

    it 'inserts nothing' do
      run!
      expect(bed_night_dates(enrollment)).to be_empty
    end
  end

  describe 'existing bed nights' do
    let!(:enrollment) { create_enrollment(entry_date: Date.new(2026, 3, 1), exit_date: Date.new(2026, 3, 4)) }
    let!(:existing) { create_bed_night(enrollment, Date.new(2026, 3, 2)) }

    it 'fills only the missing nights and leaves the existing record untouched' do
      run!
      expect(bed_night_dates(enrollment)).to contain_exactly(Date.new(2026, 3, 1), Date.new(2026, 3, 2), Date.new(2026, 3, 3))
      expect(GrdaWarehouse::Hud::Service.bed_night.where(EnrollmentID: enrollment.EnrollmentID, DateProvided: Date.new(2026, 3, 2)).pluck(:ServicesID)).
        to contain_exactly(existing.ServicesID)
    end

    it 'does not treat a non-bed-night service on the same date as a bed night' do
      create_bed_night(enrollment, Date.new(2026, 3, 3), record_type: 141, type_provided: 9)
      run!
      expect(bed_night_dates(enrollment)).to contain_exactly(Date.new(2026, 3, 1), Date.new(2026, 3, 2), Date.new(2026, 3, 3))
    end

    it 'does not treat a soft-deleted bed night as present' do
      existing.destroy
      run!
      expect(bed_night_dates(enrollment)).to contain_exactly(Date.new(2026, 3, 1), Date.new(2026, 3, 2), Date.new(2026, 3, 3))
    end

    it 'is a no-op on a second run' do
      run!
      expect { run! }.not_to(change { GrdaWarehouse::Hud::Service.bed_night.count })
    end
  end

  describe 'enrollments outside the scope' do
    let!(:in_scope) { create_enrollment(entry_date: Date.new(2026, 3, 1), exit_date: Date.new(2026, 3, 3)) }
    let!(:other_project) { create(:hud_project, data_source: data_source, ProjectType: 1) }
    let!(:elsewhere) { create_enrollment(project: other_project, entry_date: Date.new(2026, 3, 1), exit_date: Date.new(2026, 3, 3)) }
    let!(:other_data_source) { create(:grda_warehouse_data_source) }
    let!(:same_project_id_other_source) do
      create(:hud_enrollment, data_source_id: other_data_source.id, ProjectID: project.ProjectID, PersonalID: client.PersonalID,
                              EntryDate: Date.new(2026, 3, 1), UserID: 'U9')
    end

    it 'only touches enrollments at the requested projects' do
      run!
      expect(bed_night_dates(in_scope).size).to eq(2)
      expect(bed_night_dates(elsewhere)).to be_empty
    end

    it 'ignores an enrollment with the same ProjectID in another data source' do
      run!
      expect(GrdaWarehouse::Hud::Service.bed_night.where(data_source_id: other_data_source.id).count).to eq(0)
    end

    it 'raises for an unknown project pk without inserting anything' do
      expect { run!(project_pks: [project.id, -1]) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(GrdaWarehouse::Hud::Service.bed_night.count).to eq(0)
    end
  end

  describe 'batching' do
    let!(:long_stay) { create_enrollment(entry_date: Date.new(2026, 1, 1), exit_date: Date.new(2026, 1, 8)) } # 7 nights
    let!(:other_client) { create(:hud_client, data_source_id: data_source.id, PersonalID: 'C2') }
    let!(:short_stay) { create_enrollment(client: other_client, entry_date: Date.new(2026, 2, 1), exit_date: Date.new(2026, 2, 3)) } # 2 nights

    it 'inserts every night when a single client exceeds the batch size' do
      run!(batch_size: 3)
      expect(bed_night_dates(long_stay).size).to eq(7)
      expect(bed_night_dates(short_stay).size).to eq(2)
    end

    it 'rolls back all of a client\'s nights when one insert statement fails' do
      calls = 0
      allow(GrdaWarehouse::Hud::Service).to receive(:insert_all).and_wrap_original do |original, *args, **kwargs|
        calls += 1
        raise ActiveRecord::StatementInvalid, 'simulated failure' if calls == 2

        original.call(*args, **kwargs)
      end

      expect { run!(batch_size: 3) }.to raise_error(ActiveRecord::StatementInvalid, 'simulated failure')
      expect(GrdaWarehouse::Hud::Service.bed_night.count).to eq(0)
    end

    it 'invalidates processing for clients whose nights committed before a later insert fails' do
      GrdaWarehouse::Hud::Enrollment.where(id: [long_stay.id, short_stay.id]).update_all(processed_as: 'stale')
      calls = 0
      allow(GrdaWarehouse::Hud::Service).to receive(:insert_all).and_wrap_original do |original, *args, **kwargs|
        calls += 1
        # long_stay flushes in three statements; the fourth is short_stay
        raise ActiveRecord::StatementInvalid, 'simulated failure' if calls == 4

        original.call(*args, **kwargs)
      end

      expect { run!(batch_size: 3) }.to raise_error(ActiveRecord::StatementInvalid, 'simulated failure')
      expect(bed_night_dates(long_stay).size).to eq(7)
      expect(long_stay.reload.processed_as).to be_nil
      expect(short_stay.reload.processed_as).to eq('stale')
    end
  end

  describe 'an enrollment without a UserID' do
    let!(:enrollment) { create_enrollment(entry_date: Date.new(2026, 3, 1), exit_date: Date.new(2026, 3, 3), user_id: nil) }
    let!(:blank_user_enrollment) do
      create_enrollment(entry_date: Date.new(2026, 3, 1), exit_date: Date.new(2026, 3, 3), user_id: '', client: create(:hud_client, data_source_id: data_source.id, PersonalID: 'C3'))
    end

    it 'stamps the data source system user on the bed nights' do
      run!
      system_user_id = Hmis::Hud::User.system_user(data_source_id: data_source.id).UserID
      expect(system_user_id).to be_present
      expect(GrdaWarehouse::Hud::Service.bed_night.where(EnrollmentID: enrollment.EnrollmentID).pluck(:UserID).uniq).to eq([system_user_id])
      expect(GrdaWarehouse::Hud::Service.bed_night.where(EnrollmentID: blank_user_enrollment.EnrollmentID).pluck(:UserID).uniq).to eq([system_user_id])
    end
  end

  describe 'dry run' do
    let!(:enrollment) { create_enrollment(entry_date: Date.new(2026, 3, 1), exit_date: Date.new(2026, 3, 4)) }

    before { enrollment.update_columns(processed_as: 'stale') }

    it 'reports what would be inserted without writing or invalidating anything' do
      allow($stdout).to receive(:puts)
      summary = run!(dry_run: true)

      expect(summary.inserted).to eq(3)
      expect(summary.dry_run).to be(true)
      expect(GrdaWarehouse::Hud::Service.bed_night.count).to eq(0)
      expect(enrollment.reload.processed_as).to eq('stale')
      expect($stdout).to have_received(:puts).with(a_string_including('[DRY RUN]', 'would insert 3 bed nights'))
    end
  end

  describe 'scope summary' do
    let!(:exited) { create_enrollment(entry_date: Date.new(2026, 3, 1), exit_date: Date.new(2026, 3, 4)) } # 3 candidate nights
    let!(:open) { create_enrollment(entry_date: today - 2.days) } # 2 candidate nights
    let!(:same_day) { create_enrollment(entry_date: Date.new(2026, 4, 1), exit_date: Date.new(2026, 4, 1)) } # 0 candidate nights

    before { create_bed_night(exited, Date.new(2026, 3, 2)) }

    it 'counts enrollments, candidate nights, and existing bed nights per project' do
      allow($stdout).to receive(:puts)
      summary = run!(dry_run: true)
      project_summary = summary.projects.sole

      expect(project_summary).to have_attributes(
        project_pk: project.id,
        project_name: project.ProjectName,
        enrollment_count: 3,
        candidate_nights: 5,
        existing_nights: 1,
        inserted: 4,
      )
    end
  end

  describe 'post-insert processing' do
    let!(:enrollment) { create_enrollment(entry_date: Date.new(2026, 3, 1), exit_date: Date.new(2026, 3, 3)) }

    before { enrollment.update_columns(processed_as: 'stale') }

    it 'clears processed_as on touched enrollments and queues service history processing' do
      allow(Hmis::Hud::Service).to receive(:queue_service_history_processing!)
      run!
      expect(enrollment.reload.processed_as).to be_nil
      expect(Hmis::Hud::Service).to have_received(:queue_service_history_processing!).once
    end
  end
end
