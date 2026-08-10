###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'UserTrainingController', type: :request do
  let(:user) { create(:user) }
  let(:lms_double) do
    instance_double(
      Talentlms::Facade,
      any_training_required?: false,
    )
  end

  before do
    allow_any_instance_of(User).to receive(:required_training_courses).and_return([])
    allow(Talentlms::Facade).to receive(:new).and_return(lms_double)
    # Stub the TalentLMS API validation to prevent actual API calls in tests
    allow_any_instance_of(Talentlms::Config).to receive(:check_configuration_is_valid).and_return(true)
    allow_any_instance_of(Talentlms::Course).to receive(:check_configuration_is_valid).and_return(true)
    sign_in user
  end

  describe 'GET /user_training' do
    it 'redirects to the stored location when it is safe', :devise_only do
      # Canary: Verify that stored_location_for exists (from Devise)
      # If Devise is removed, this test will fail and you'll need to reimplement the stored location functionality
      expect(UserTrainingController.instance_methods).to(
        include(:stored_location_for),
        'stored_location_for method not found - has Devise been removed? If so, update this test and reimplement stored location functionality.',
      )

      # Mock stored_location_for to return our desired path
      # We mock this because session persistence between requests is complex in request specs
      allow_any_instance_of(UserTrainingController).to receive(:stored_location_for).with(:user).and_return('/welcome_back')

      get user_training_path

      expect(response).to redirect_to('/welcome_back')
    end

    it 'falls back when the stored location points to the training portal', :devise_only do
      # Canary: Verify that stored_location_for exists (from Devise)
      expect(UserTrainingController.instance_methods).to(
        include(:stored_location_for),
        'stored_location_for method not found - has Devise been removed? If so, update this test.',
      )

      # Mock to simulate stored location pointing to training portal
      allow_any_instance_of(UserTrainingController).to receive(:stored_location_for).with(:user).and_return(user_training_path)

      get user_training_path

      expect(response).to redirect_to(root_path)
    end

    it 'redirects to the user root without reading a stored location', :jwt_only do
      # Devise defines stored_location_for even under AUTH_METHOD=jwt, so this has something to catch.
      expect_any_instance_of(UserTrainingController).not_to receive(:stored_location_for)

      allow_any_instance_of(User).to receive(:my_root_path).and_return(censuses_path)

      get user_training_path

      expect(response).to redirect_to(censuses_path)
    end

    it 'lets a user continue when all required trainings are completed' do
      # Setup: Create course, config, login, and completed training
      config = create(:talentlms_config)
      course = create(
        :default_course,
        config: config,
        courseid: 123,
      )
      login = create(
        :talentlms_login,
        user: user,
        config: config,
        lms_user_id: 456,
      )
      create(
        :talentlms_completed_training,
        login: login,
        config: config,
        course_id: course.id,
        completion_date: Date.today,
      )

      # Mock the required_training_courses to return our course
      allow_any_instance_of(User).to receive(:required_training_courses).and_return([course])

      # Mock the LMS facade to indicate no training is required
      allow(lms_double).to receive(:any_training_required?).and_return(false)

      get user_training_path

      # Should redirect to after_sign_in_path_for
      expect(response).to redirect_to(root_path)
    end

    it 'lets a user continue when the portal finds every required training complete' do
      config = create(:talentlms_config)
      course = create(
        :default_course,
        config: config,
        courseid: 123,
      )
      create(
        :talentlms_login,
        user: user,
        config: config,
        lms_user_id: 456,
      )

      allow_any_instance_of(User).to receive(:required_training_courses).and_return([course])
      allow_any_instance_of(User).to receive(:my_root_path).and_return(censuses_path)

      allow(lms_double).to receive(:any_training_required?).and_return(true)
      allow(lms_double).to receive(:login).with(config).and_return(true)
      allow(lms_double).to receive(:enroll).with(config, course.courseid)
      allow(lms_double).to receive(:training_expired?).with(config, course.courseid).and_return(false)
      allow(lms_double).to receive(:complete?).with(config, course.courseid).and_return(Date.today)
      allow(lms_double).to receive(:valid_date?).with(Date.today).and_return(true)
      allow(lms_double).to receive(:log_course_completion).with(config, course.courseid, Date.today)

      get user_training_path

      expect(response).to redirect_to(censuses_path)
    end

    it 'presents the captive portal when a required training is incomplete' do
      # Setup: Create course and config, but NO completed training
      config = create(:talentlms_config, allow_automatic_redirect_to_course: false)
      course = create(
        :default_course,
        config: config,
        courseid: 123,
      )

      # Mock the required_training_courses to return our course
      allow_any_instance_of(User).to receive(:required_training_courses).and_return([course])

      # Mock the LMS facade to indicate training IS required
      allow(lms_double).to receive(:any_training_required?).and_return(true)
      allow(lms_double).to receive(:login).with(config).and_return(true)
      allow(lms_double).to receive(:enroll).with(
        config,
        course.courseid,
      )
      allow(lms_double).to receive(:training_expired?).with(
        config,
        course.courseid,
      ).and_return(false)
      allow(lms_double).to receive(:complete?).with(
        config,
        course.courseid,
      ).and_return(false)
      allow(lms_double).to receive(:valid_date?).with(false).and_return(false)
      allow(lms_double).to receive(:course_url).and_return('https://example.talentlms.com/course/123')
      allow(lms_double).to receive(:active_user?).with(config).and_return(true)

      get user_training_path

      # Should render the captive portal
      expect(response).to render_template('required_trainings')
    end
  end

  describe 'DELETE /users/sign_out while a required training is incomplete' do
    before do
      allow_any_instance_of(User).to receive(:training_required?).and_return(true)
      allow(lms_double).to receive(:any_training_required?).and_return(true)
    end

    it 'hands the request to the proxy sign-out rather than the portal', :jwt_only do
      allow_any_instance_of(Idp::SessionsController).to receive(:idp_end_token_holder_sessions)

      delete destroy_user_session_path

      expect(response).to redirect_to("/oauth2/sign_out?rd=#{CGI.escape(root_path)}")
    end

    it 'runs the Devise sign-out rather than returning to the portal', :devise_only do
      delete destroy_user_session_path

      expect(response).to redirect_to(root_url)
    end
  end
end
