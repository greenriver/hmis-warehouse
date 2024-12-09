require 'rails_helper'

RSpec.describe Talentlms::Facade, type: :model do
  before(:all) do
    GrdaWarehouse::Utility.clear!
  end

  DEFAULT_LMS_USERNAME = 'username'.freeze
  DEFAULT_LMS_EMAIL = 'lms_user_email@greenriver.org'.freeze
  DEFAULT_LMS_USER_ID = 1
  UPDATED_LMS_USERNAME = 'updated_username'.freeze
  UPDATED_LMS_EMAIL = 'updated_lms_user_email@greenriver.org'.freeze
  UPDATED_LMS_USER_ID = 1234
  COMPLETED_ON_DATETIME = DateTime.current.strftime('%Y/%m/%d, %T').freeze
  COURSE_URL = 'www.google.com'.freeze

  let(:training_role) { create(:role, training_required: true) }
  let!(:user) do
    user = create(:user, talent_lms_email: DEFAULT_LMS_EMAIL)
    training_role.add(user)
    user
  end
  let!(:config) do
    # We need to skip validation on save so we can setup the stubs prior to validation running on this object.
    config = Talentlms::Config.new(subdomain: 'test', api_key: '1234')
    config.save(validate: false)
    config
  end
  let!(:course1) { create :default_course, courseid: 1, config: config, name: 'Course1' }
  let!(:course2) { create :default_course, courseid: 2, config: config, name: 'Course2' }
  let!(:lms_login) { create :talentlms_login, user: user, config: config, login: DEFAULT_LMS_USERNAME }
  let!(:lms) { Talentlms::Facade.new(user) }

  before do
    setup_stubs(config: config)
  end

  describe 'local_login' do
    it 'pulls from local if it exists' do
      local_lms_login = Talentlms::Login.first
      expect(lms.local_login(config)).to eq(local_lms_login)
    end

    it 'login record is created if it does not exist locally but does exist in API' do
      lms_login.destroy
      expect(Talentlms::Login.first).to be_nil
      login = lms.local_login(config)
      expect(Talentlms::Login.first).to_not be_nil
      expect(login).to_not be_nil
    end

    it 'login record is created if it does not exist locally and does not exist in API and config allows' do
      stub_so_api_does_not_recognize_get_user(config: config)
      lms_login.destroy

      expect(Talentlms::Login.first).to be_nil
      login = lms.local_login(config)
      expect(Talentlms::Login.first).to_not be_nil
      expect(login).to_not be_nil
    end

    it 'is not created if it doesnt exist locally and does not exist in API and config does not allow' do
      stub_so_api_does_not_recognize_get_user(config: config)
      lms_login.destroy
      config.update(create_new_accounts: false)

      expect(Talentlms::Login.first).to be_nil
      login = lms.local_login(config)
      expect(Talentlms::Login.first).to be_nil
      expect(login).to be_nil
    end
  end

  describe 'sync_lms_account' do
    it 'local data remains the same when user data matches api data' do
      login = Talentlms::Login.where(user: user).first
      expect([login.login, login.lms_user_id]).to eq([DEFAULT_LMS_USERNAME, DEFAULT_LMS_USER_ID])

      lms.sync_lms_account(config, lms_login)
      login = Talentlms::Login.where(user: user).first
      expect([login.login, login.lms_user_id]).to eq([DEFAULT_LMS_USERNAME, DEFAULT_LMS_USER_ID])
      expect(user.talent_lms_email).to eq(DEFAULT_LMS_EMAIL)
    end

    it 'local data is updated when user data does not match api user data' do
      stub_so_api_user_does_not_matches_local_user(config: config)

      login = Talentlms::Login.where(user: user).first
      expect([login.login, login.lms_user_id]).to eq([DEFAULT_LMS_USERNAME, DEFAULT_LMS_USER_ID])
      expect(user.talent_lms_email).to eq(DEFAULT_LMS_EMAIL)

      lms.sync_lms_account(config, lms_login)
      login = Talentlms::Login.where(user: user).first
      expect([login.login, login.lms_user_id]).to eq([UPDATED_LMS_USERNAME, UPDATED_LMS_USER_ID])
      expect(user.talent_lms_email).to eq(UPDATED_LMS_EMAIL)
    end

    it 'a new account is not created if config disallows user creation and local user cannot be found in API' do
      config.update(create_new_accounts: false)
      stub_so_api_does_not_recognize_get_user(config: config)

      login = Talentlms::Login.where(user: user).first
      expect([login.login, login.lms_user_id]).to eq([DEFAULT_LMS_USERNAME, DEFAULT_LMS_USER_ID])

      lms.sync_lms_account(config, lms_login)
      login = Talentlms::Login.where(user: user).first
      expect([login.login, login.lms_user_id]).to eq([DEFAULT_LMS_USERNAME, DEFAULT_LMS_USER_ID])
      expect(user.talent_lms_email).to eq(DEFAULT_LMS_EMAIL)
    end

    it 'a new account is not created if config disallows user creation and local user data does not exist' do
      config.update(create_new_accounts: false)
      stub_so_api_does_not_recognize_get_user(config: config)
      lms_login.destroy

      expect(Talentlms::Login.first).to be_nil

      lms.sync_lms_account(config, lms_login)
      expect(Talentlms::Login.first).to be_nil
      expect(user.talent_lms_email).to eq(DEFAULT_LMS_EMAIL)
    end
  end

  describe 'create_account' do
    before do
      stub_so_api_does_not_recognize_get_user(config: config)
      lms_login.destroy
    end

    it 'a new account is created if the config allows account creation' do
      config.update(create_new_accounts: true)
      expect(lms.create_account(config)).to_not be_nil
    end

    it 'a new account is not created if the config disallows account creation' do
      config.update(create_new_accounts: false)
      expect(lms.create_account(config)).to be_nil
    end
  end

  describe 'log_course_completion' do
    it 'does nothing if login does not exist' do
      stub_so_api_does_not_recognize_get_user(config: config)
      lms_login.destroy
      config.update(create_new_accounts: false)
      expect(Talentlms::Login.first).to be_nil
      expect(Talentlms::CompletedTraining.first).to be_nil
      lms.log_course_completion(config, course1.courseid, DateTime.current)
      expect(Talentlms::CompletedTraining.first).to be_nil
    end

    it 'training completion is logged if login exists' do
      expect(Talentlms::Login.first).to_not be_nil
      expect(Talentlms::CompletedTraining.first).to be_nil
      completed_on = DateTime.current
      lms.log_course_completion(config, course1.courseid, completed_on)
      completed_training = Talentlms::CompletedTraining.first
      result = [
        completed_training.completion_date,
        completed_training.course_id,
        completed_training.login_id,
      ]
      expected = [
        completed_on.to_date,
        course1.id,
        Talentlms::Login.first.id,
      ]
      expect(result).to eq(expected)
    end
  end

  describe 'complete?' do
    it 'returns false if training is not completed' do
      stub_course_to_return_not_completed(config: config)
      expect(lms.complete?(config, course1.courseid)).to be false
    end

    it 'returns completed on datetime if training is completed' do
      expect(lms.complete?(config, course1.courseid)).to eq(COMPLETED_ON_DATETIME)
    end
  end

  describe 'training_expired?' do
    it 'returns false if months_to_expiration is not set' do
      course1.update(months_to_expiration: nil)
      expect(lms.training_expired?(config, course1.courseid)).to be false
    end

    it 'returns false if months_to_expiration is set but completion is within range' do
      course1.update(months_to_expiration: 2)
      lms.log_course_completion(config, course1.courseid, 1.days.ago)
      expect(lms.training_expired?(config, course1.courseid)).to be false
    end

    it 'returns true if months_to_expiration is set and completion date is expired (local)' do
      course1.update(months_to_expiration: 2)
      lms.log_course_completion(config, course1.courseid, 5.days.ago)
      expect(lms.training_expired?(config, course1.courseid, false)).to be true
    end

    it 'returns true if months_to_expiration is set and completion date is expired (api)' do
      course1.update(months_to_expiration: 2)
      stub_course_to_return_completion_date(config: config, date: 5.days.ago)
      expect(lms.training_expired?(config, course1.courseid, true)).to be true
    end
  end

  describe 'training_required?' do
    it 'returns nil if user does not require training' do
      training_role.remove(user)
      user = User.first
      lms = Talentlms::Facade.new(user)
      # Verify user does not require training
      expect(user.training_required?).to_not be true
      # Verify Training is required
      expect(lms.training_required?(config, course1.courseid)).to be nil
    end
    it 'returns true if training has not been completed but is required' do
      # Verify Training is not completed
      expect(Talentlms::CompletedTraining.where(login: lms_login).count).to eq(0)
      # Verify Training is required
      expect(lms.training_required?(config, course1.courseid)).to be true
    end
    it 'returns true if training has been completed but is expired' do
      course1.update(months_to_expiration: 1)
      lms.log_course_completion(config, course1.courseid, 5.days.ago)
      # Verify training is expired
      expect(lms.training_expired?(config, course1.courseid, false)).to be true
      # Verify Training is completed
      expect(Talentlms::CompletedTraining.where(login: lms_login, course: course1).present?).to be true
      # Verify Training is required
      expect(lms.training_required?(config, course1.courseid)).to be true
    end
    it 'returns false if training has been completed and is not expired' do
      course1.update(months_to_expiration: 5)
      lms.log_course_completion(config, course1.courseid, 1.days.ago)
      # Verify training is not expired
      expect(lms.training_expired?(config, course1.courseid, false)).to be false
      # Verify Training is completed
      expect(Talentlms::CompletedTraining.where(login: lms_login, course: course1).present?).to be true
      # Verify Training is not required
      expect(lms.training_required?(config, course1.courseid)).to be false
    end
  end

  describe 'any_training_required?' do
    before do
      # Verify 2 default courses exist
      expect(Talentlms::Course.default.count).to eq(2)
    end
    it 'All courses are required and no courses are completed' do
      # Set config to require all courses to be complete
      GrdaWarehouse::Config.first_or_create.update(number_lms_courses_required: -1)
      # Verify no courses have been completed
      expect(Talentlms::CompletedTraining.where(login: lms_login).count).to eq(0)
      # Verify training is required
      expect(lms.any_training_required?).to be true
    end
    it 'All courses are required and 1+ but not all are completed' do
      # Set config to require all courses to be complete
      GrdaWarehouse::Config.first_or_create.update(number_lms_courses_required: -1)
      # Log & verify course completion
      lms.log_course_completion(config, course1.courseid, DateTime.current)
      expect(Talentlms::CompletedTraining.where(login: lms_login).count).to eq(1)
      # Verify training is required
      expect(lms.any_training_required?).to be true
    end
    it 'All courses are required and 1+ but not all are completed' do
      # Set config to require all courses to be complete
      GrdaWarehouse::Config.first_or_create.update(number_lms_courses_required: -1)
      # Log & verify course completion
      lms.log_course_completion(config, course1.courseid, DateTime.current)
      lms.log_course_completion(config, course2.courseid, DateTime.current)
      expect(Talentlms::CompletedTraining.where(login: lms_login).count).to eq(2)
      # Verify training is not required
      expect(lms.any_training_required?).to be false
    end
    it 'Any of One course is required and 1 but not all are completed' do
      # Set config to require only 1 course completion
      GrdaWarehouse::Config.first_or_create.update(number_lms_courses_required: 1)
      expect(Talentlms::CompletedTraining.where(login: lms_login).count).to eq(0)
      # Verify training is required
      expect(lms.any_training_required?).to be true
    end
    it 'Any of One course is and 1+ but not all are completed' do
      # Set config to require only 1 course completion
      GrdaWarehouse::Config.first_or_create.update(number_lms_courses_required: 1)
      # Log & verify course completion
      lms.log_course_completion(config, course1.courseid, DateTime.current)
      expect(Talentlms::CompletedTraining.where(login: lms_login).count).to eq(1)
      # Verify training is not required
      expect(lms.any_training_required?).to be false
    end
    it 'Any of One course is and 1+ but not all are completed' do
      # Set config to require only 1 course completion
      GrdaWarehouse::Config.first_or_create.update(number_lms_courses_required: 1)
      # Log & verify course completions
      lms.log_course_completion(config, course1.courseid, DateTime.current)
      lms.log_course_completion(config, course2.courseid, DateTime.current)
      expect(Talentlms::CompletedTraining.where(login: lms_login).count).to eq(2)
      # Verify training is not required
      expect(lms.any_training_required?).to be false
    end
  end

  # ----------------------------- Stub Defaults -----------------------------
  def setup_stubs(config:)
    allow(config).to receive(:get).with(
      anything,
    ).and_return(
      {
        this_is_fake_get_data: true,
      },
    )

    allow(config).to receive(:get).with(
      anything,
      anything,
    ).and_return(
      {
        this_is_fake_get_data: true,
      },
    )

    allow(config).to receive(:post).with(
      anything,
      anything,
    ).and_return(
      {
        this_is_fake_post_data: true,
      },
    )

    allow(config).to receive(:get).with(
      'getuserstatusincourse',
      anything,
    ).and_return(
      {
        'completion_status' => 'Completed',
        'completed_on' => COMPLETED_ON_DATETIME,
      },
    )

    allow(config).to receive(:get).with(
      'gotocourse',
      anything,
    ).and_return(
      {
        'goto_url' => COURSE_URL,
      },
    )

    allow(config).to receive(:post).with(
      'users',
      anything,
    ).and_return(
      {
        'email' => DEFAULT_LMS_EMAIL,
        'login' => DEFAULT_LMS_USERNAME,
        'id' => DEFAULT_LMS_USER_ID,
      },
    )

    allow(config).to receive(:post).with(
      'usersignup',
      anything,
    ).and_return(
      {
        'email' => DEFAULT_LMS_EMAIL,
        'login' => DEFAULT_LMS_USERNAME,
        'id' => DEFAULT_LMS_USER_ID,
      },
    )
  end

  # ----------------------------- Stub Overrides -----------------------------

  def stub_so_api_does_not_recognize_get_user(config:)
    allow(config).to receive(:post).with(
      'users',
      anything,
    ).and_return(
      nil,
    )
  end

  def stub_so_api_user_does_not_matches_local_user(config:)
    allow(config).to receive(:post).with(
      'users',
      anything,
    ).and_return(
      {
        'email' => UPDATED_LMS_EMAIL,
        'login' => UPDATED_LMS_USERNAME,
        'id' => UPDATED_LMS_USER_ID,
      },
    )
  end

  def stub_course_to_return_not_completed(config:)
    allow(config).to receive(:get).with(
      'getuserstatusincourse',
      anything,
    ).and_return(
      {
        'completion_status' => 'not_attempted',
        'completed_on' => '',
      },
    )
  end

  def stub_course_to_return_completion_date(config:, date:)
    allow(config).to receive(:get).with(
      'getuserstatusincourse',
      anything,
    ).and_return(
      {
        'completion_status' => 'Completed',
        'completed_on' => date.strftime('%Y/%m/%d, %T').freeze,
      },
    )
  end
end
