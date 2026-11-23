###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'ostruct'
require 'rails_helper'
require_relative '../../support/hmis_base_setup'
require_relative '../../requests/hmis/login_and_permissions'

RSpec.describe Hmis::StaffAssignment, type: :model do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1 }
  let!(:e_other) { create :hmis_hud_enrollment, data_source: ds1, project: p1 }
  let!(:ar) { create :hmis_staff_assignment_relationship }
  let!(:assignment) { create :hmis_staff_assignment, staff_assignment_relationship: ar, data_source: ds1, enrollment: e1, user: hmis_user }

  it 'combines the lateral household scopes with joins(:household)' do
    scope = described_class.viewable_by(hmis_user).open_on_date.order_by_household_most_recent.joins(:household)
    expect(scope).to contain_exactly(assignment)
  end

  it 'filters enrollments by assigned staff' do
    filtered = Hmis::Filter::EnrollmentFilter.new(OpenStruct.new(assigned_staff: hmis_user.id)).
      filter_scope(Hmis::Hud::Enrollment.where(id: [e1.id, e_other.id]))
    expect(filtered).to contain_exactly(e1)
  end
end
