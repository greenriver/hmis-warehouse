###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../spec/shared_contexts/hud_enrollment_builders'

RSpec.describe 'Performance Measurement bed days', type: :model do
  include_context 'HUD enrollment builders'

  let(:test_start_date) { '2022-10-01'.to_date }
  let(:test_end_date) { '2023-09-30'.to_date }
  def run_report(projects)
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    PerformanceMeasurement::Goal.ensure_default
    report = PerformanceMeasurement::Report.new(user_id: User.system_user.id)
    report.filter = Filters::HudFilterBase.new(
      user_id: User.system_user.id,
      start: test_start_date,
      end: test_end_date,
      coc_code: 'MA-500',
      coc_codes: ['MA-500'],
      project_ids: projects.map(&:id),
      project_type_codes: HudHelper.util.residential_project_type_numbers_by_code.keys,
      enforce_one_year_range: false,
    )
    report.update_goal_configuration!
    report.save!
    report.run_and_save!
    report.reload
  end

  def bed_days(report, client, column)
    report.clients.find_by(client_id: client.destination_client.id)&.public_send(column).to_i
  end

  # Each enrollment runs 60 days; those with a move-in date move in after 20 of them.
  let(:entry_date) { test_start_date + 30.days }
  let(:move_in_date) { entry_date + 20.days }
  let(:exit_date) { entry_date + 60.days }

  let(:rrh_housing) { create_project(project_type: 13).tap { |p| p.update!(RRHSubType: 2) } }
  let(:rrh_sso) { create_project(project_type: 13).tap { |p| p.update!(RRHSubType: 1) } }
  let(:psh) { create_project(project_type: 3) }
  let(:es) { create_project(project_type: 0) }

  let!(:rrh_housing_moved_in) { create_client_with_warehouse_link }
  let!(:rrh_housing_not_moved_in) { create_client_with_warehouse_link }
  let!(:rrh_sso_moved_in) { create_client_with_warehouse_link }
  let!(:rrh_sso_not_moved_in) { create_client_with_warehouse_link }
  let!(:rrh_household_member) { create_client_with_warehouse_link }
  let!(:psh_moved_in) { create_client_with_warehouse_link }
  let!(:psh_not_moved_in) { create_client_with_warehouse_link }
  let!(:es_client) { create_client_with_warehouse_link }

  let!(:report) do
    [
      [rrh_housing_not_moved_in, rrh_housing, nil],
      [rrh_sso_moved_in, rrh_sso, move_in_date],
      [rrh_sso_not_moved_in, rrh_sso, nil],
      [psh_moved_in, psh, move_in_date],
      [psh_not_moved_in, psh, nil],
      [es_client, es, nil],
    ].each do |client, project, move_in|
      create_enrollment(client: client, project: project, entry_date: entry_date, exit_date: exit_date, move_in_date: move_in)
    end
    # A household member with no move-in date of their own takes the head of household's.
    household_id = Hmis::Hud::Base.generate_uuid
    create_enrollment(client: rrh_housing_moved_in, project: rrh_housing, entry_date: entry_date, exit_date: exit_date, move_in_date: move_in_date, household_id: household_id)
    create_enrollment(client: rrh_household_member, project: rrh_housing, entry_date: entry_date, exit_date: exit_date, relationship_to_ho_h: 2, household_id: household_id)
    run_report([rrh_housing, rrh_sso, psh, es])
  end

  it 'counts PH bed days only from the move-in date and ES bed days for the whole stay' do
    days = {
      rrh_housing_moved_in: bed_days(report, rrh_housing_moved_in, :reporting_days_in_rrh_bed_in_period),
      rrh_housing_not_moved_in: bed_days(report, rrh_housing_not_moved_in, :reporting_days_in_rrh_bed_in_period),
      rrh_sso_moved_in: bed_days(report, rrh_sso_moved_in, :reporting_days_in_rrh_bed_in_period),
      rrh_sso_not_moved_in: bed_days(report, rrh_sso_not_moved_in, :reporting_days_in_rrh_bed_in_period),
      rrh_household_member: bed_days(report, rrh_household_member, :reporting_days_in_rrh_bed_in_period),
      psh_moved_in: bed_days(report, psh_moved_in, :reporting_days_in_psh_bed_in_period),
      psh_not_moved_in: bed_days(report, psh_not_moved_in, :reporting_days_in_psh_bed_in_period),
      es_client: bed_days(report, es_client, :reporting_days_in_es_bed_in_period),
    }

    expect(days).to eq(
      rrh_housing_moved_in: 40,
      rrh_housing_not_moved_in: 0,
      rrh_sso_moved_in: 40,
      rrh_sso_not_moved_in: 0,
      rrh_household_member: 40,
      psh_moved_in: 40,
      psh_not_moved_in: 0,
      es_client: 60,
    )
  end
end
