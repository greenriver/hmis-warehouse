###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HapReport::Report, type: :model do
  before(:all) do
    HmisCsvTwentyTwenty::Utility.clear!
    GrdaWarehouse::Utility.clear!
    import_hmis_csv_fixture(
      'drivers/hap_report/spec/fixtures/files/fy2020/default',
      version: 'AutoMigrate',
      run_jobs: true,
    )
  end

  after(:all) do
    # The access control rows built in before(:all) aren't rolled back, and
    # cleanup_test_environment only removes users
    [AccessControl, UserGroupMember, UserGroup, Role, Collection].each do |model|
      model.with_deleted.delete_all
    end
    cleanup_test_environment
  end

  def report_owner(collection)
    owner = create(:acl_user)
    role = create(:role, can_view_assigned_reports: true, can_report_on_confidential_projects: true)
    setup_access_control(owner, role, collection)
    owner
  end

  def run_report(user:, project_ids:)
    report = HapReport::Report.create!(
      user: user,
      options: {
        start: '2019-01-01'.to_date,
        end: '2019-12-31'.to_date,
        project_ids: project_ids,
      },
    )
    report.run_and_save!
    report
  end

  describe 'with all projects' do
    before(:all) do
      Collection.maintain_system_groups
      owner = report_owner(Collection.system_collection(:data_sources))
      @report = run_report(user: owner, project_ids: GrdaWarehouse::Hud::Project.pluck(:id))
    end

    it 'finds households with children' do
      expect(value(:head_of_households_with_children, :total)).to eq(2)
    end

    it 'finds households without children' do
      expect(value(:head_of_adult_only_households, :total)).to eq(5)
    end

    it 'finds adult es clients' do
      expect(value(:adults_served, :emergency_shelter)).to eq(6)
    end

    it 'all adult clients are es' do
      expect(value(:adults_served, :total)).to eq(6)
    end

    it 'counts all clients' do
      expect(value(:total_clients_served, :total)).to eq(9)
    end
  end

  describe 'with a project the owner cannot see' do
    before(:all) do
      visible_project = GrdaWarehouse::Hud::Project.find_by!(ProjectID: 'NBN')
      invisible_project = GrdaWarehouse::Hud::Project.find_by!(ProjectID: 'DEFAULT-ES')
      collection = create(:collection)
      collection.set_viewables({ projects: [visible_project.id] })
      owner = report_owner(collection)
      @report = run_report(user: owner, project_ids: [invisible_project.id])

      control_collection = create(:collection)
      control_collection.set_viewables({ projects: [invisible_project.id] })
      control_owner = report_owner(control_collection)
      @control_report = run_report(user: control_owner, project_ids: [invisible_project.id])
    end

    it 'counts clients in the project for an owner who can see it' do
      expect(@control_report.cell('total_clients_served_total').summary).to be > 0
    end

    it 'counts no clients' do
      expect(value(:total_clients_served, :total)).to eq(0)
    end
  end

  # DEPRECATED_FY2024 - re-enable after 2024 importer and migrator are in-place
  # until then, night_by_night scope will return all ES 1 regardless of TrackingMethod
  # describe 'with just NBN projects' do
  #   before(:all) do
  #     import_hmis_csv_fixture(
  #       'drivers/hap_report/spec/fixtures/files/fy2020/default',
  #       version: 'AutoMigrate',
  #       run_jobs: true,
  #     )
  #     @report = HapReport::Report.create!(
  #       options: {
  #         start: '2019-01-01'.to_date,
  #         end: '2019-12-31'.to_date,
  #         project_ids: GrdaWarehouse::Hud::Project.night_by_night.pluck(:id),
  #       },
  #     )
  #     @report.run_and_save!
  #   end

  #   it 'sees only one night' do
  #     expect(value(:total_units_of_shelter_service, :emergency_shelter)).to eq(1)
  #   end
  # end

  def value(row, column)
    @report.cell("#{row}_#{column}").summary
  end
end
