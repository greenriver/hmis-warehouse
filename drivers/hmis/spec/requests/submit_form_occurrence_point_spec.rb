###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'hmis/login_and_permissions'
require_relative '../support/hmis_base_setup'
require_relative '../support/submit_form_spec_helpers'

RSpec.describe 'SubmitForm for OCCURRENCE_POINT', type: :request do
  include_context 'hmis base setup'
  before(:each) do
    hmis_login(user)
  end

  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }
  let!(:definition) { create :occurrence_point_form }

  let(:move_in_date) { '2024-06-01' }

  let(:input) do
    {
      form_definition_id: definition.id,
      record_id: e1.id,
      values: { 'date' => move_in_date },
      hud_values: { 'Enrollment.moveInDate' => move_in_date },
    }
  end

  it 'saves the move-in date on the enrollment' do
    expect do
      submit_form(input)
      e1.reload
    end.to change(e1, :move_in_date).from(nil).to(Date.parse(move_in_date))
  end

  context 'when user lacks can_edit_enrollments permission' do
    before { remove_permissions(access_control, :can_edit_enrollments) }

    it 'returns access denied' do
      expect_gql_error submit_form(input, expect_raise: true), message: /not authorized/
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include SubmitFormSpecHelpers
end
