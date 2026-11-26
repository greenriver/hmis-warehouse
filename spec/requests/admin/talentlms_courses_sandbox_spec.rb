###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::TalentlmsCoursesController, type: :request do
  let!(:user) { create :acl_user }
  let!(:role) { create :admin_role }
  let!(:collection) { create :collection }
  let(:config) { create :talentlms_config }
  let(:params) { { talentlms_course: { name: 'Privacy 101', config_id: config.id, courseid: 42 } } }

  before do
    setup_access_control(user, role, collection)
    sign_in user
    stub_request(:any, /talentlms/).to_return(body: [].to_json)
    config
    WebMock::RequestRegistry.instance.reset!
  end

  it 'saves a course without contacting TalentLMS in sandbox mode' do
    with_sandbox_mode do
      expect { post admin_talentlms_courses_path, params: params }.to change(Talentlms::Course, :count).by(1)
    end

    expect(response).to redirect_to(admin_talentlms_path)
    expect(WebMock).not_to have_requested(:any, /talentlms/)
  end

  it 'validates the course against TalentLMS outside sandbox mode' do
    expect { post admin_talentlms_courses_path, params: params }.to change(Talentlms::Course, :count).by(1)

    expect(WebMock).to have_requested(:get, /courses\/id:/).once
  end
end
