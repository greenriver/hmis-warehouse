###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
    it 'redirects to the stored location when it is safe' do
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

    it 'falls back when the stored location points to the training portal' do
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
end
