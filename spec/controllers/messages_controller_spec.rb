require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  let! :user  { create :user }
  let! :event { create :message, user: user }

  before(:each) do
    authenticate(user)
  end

  after(:each) do
    user.messages.destroy_all
  end

  describe 'GET poll' do
    it "only gets yesterday's event" do
      get :poll
      expected_response = [
        "/messages/#{event.id}",
        event.id,
        event.subject,
      ]
      expect(response.body).to eq [expected_response].to_json
    end
  end

  describe 'POST seen' do
    it "sets seen_at to expected date" do
      Timecop.freeze
      post :seen, id: event.id

      # the accessor gives us a ActiveSupport::TimeWithZone, which throws things off a bit
      seen_at = event.reload&.seen_at&.to_datetime

      expect(seen_at&.hour).to eq DateTime.current.hour
      expect(seen_at&.minute).to eq DateTime.current.minute
      expect(seen_at&.second).to eq DateTime.current.second
    end
  end
end
