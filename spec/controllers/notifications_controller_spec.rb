require 'rails_helper'

RSpec.describe NotificationsController, type: :controller do
  let!(:user) { create :user }

  before(:each) do
    authenticate(user)
  end

  after(:each) do
    Notification.for(user).destroy_all
  end

  describe 'GET poll' do
    describe 'daily user' do
      it "only gets yesterday's event" do

        start_day = Time.local 2018, 1, 1, 1, 1, 1 # 2018-1-1 1:01:01 AM
        Timecop.travel start_day
        yesterdays_event = create :notification, to: [user.email], body: 'foo'
        Timecop.travel start_day + 1.day
        todays_event = create :notification, to: [user.email], body: 'bar'

        user.notify_daily = true
        user.save
        get :poll
        expect(response.body).to eq [yesterdays_event.reload].to_json
        expect(yesterdays_event.sent_at.nil?).to be false
        expect(todays_event.reload.sent_at.nil?).to be true
      end

    end

    describe 'continuous user' do
      it "gets both events" do

        start_day = Time.local 2018, 1, 1, 1, 1, 1 # 2018-1-1 1:01:01 AM
        Timecop.travel start_day
        yesterdays_event = create :notification, to: [user.email], body: 'foo'
        Timecop.travel start_day + 1.day
        todays_event = create :notification, to: [user.email], body: 'bar'

        user.notify_daily = false
        user.save
        get :poll
        expect(response.body).to eq [ todays_event, yesterdays_event ].map(&:reload).to_json
        expect(yesterdays_event.sent_at.nil?).to be false
        expect(todays_event.sent_at.nil?).to be false
      end

    end

  end

  describe 'POST seen' do
    it "sets seen_at to expected date" do
      Timecop.freeze

      event = create :notification, to: [user.email]

      post :seen, id: event.id

      # the accessor gives us a ActiveSupport::TimeWithZone, which throws things off a bit
      seen_at = event.reload&.seen_at&.to_datetime

      expect(seen_at&.hour).to eq DateTime.current.hour
      expect(seen_at&.minute).to eq DateTime.current.minute
      expect(seen_at&.second).to eq DateTime.current.second
    end
  end
end
