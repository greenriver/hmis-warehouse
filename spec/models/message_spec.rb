require 'rails_helper'
include ActiveJob::TestHelper

RSpec.describe Message, type: :model do
  ActiveJob::Base.queue_adapter = :test
  describe 'When user email schedule set to immediate: ' do
    let!(:user) { create :user, email: "noreply-for-testing@greenriver.com", email_schedule: 'immediate' }

    describe 'Sending a message with deliver_now' do
      it 'creates a message' do 
        expect do
          TestDatabaseMailer.ping(user.email).deliver_now
        end.to change{Message.count}.by(1)
      end

      it 'sends a message' do
        expect do
          TestDatabaseMailer.ping(user.email).deliver_now
        end.to change { ActionMailer::Base.deliveries.size }.by(1)
      end
    end

    describe 'Sending a message with deliver_later' do
      it 'enqueues a job' do 
        expect {
          TestDatabaseMailer.ping(user.email).deliver_later
        }.to have_enqueued_job.on_queue('mailers')
      end

      it 'creates a message' do 
        perform_enqueued_jobs do 
          expect do
            TestDatabaseMailer.ping(user.email).deliver_later
          end.to change{Message.count}.by(1)
        end
      end

      it 'sends a message' do
        perform_enqueued_jobs do 
          expect do
            TestDatabaseMailer.ping(user.email).deliver_later
          end.to change { ActionMailer::Base.deliveries.size }.by(1)
        end
      end
    end
  end

  describe 'When user email schedule set to daily: ' do
    let!(:user) { create :user, email: "noreply-for-testing@greenriver.com", email_schedule: 'daily' }

    describe 'Sending a message with deliver_now' do
      it 'creates a message' do 
        expect do
          TestDatabaseMailer.ping(user.email).deliver_now
        end.to change{Message.count}.by(1)
      end

      it 'does not send a message' do
        expect do
          TestDatabaseMailer.ping(user.email).deliver_now
        end.to change { ActionMailer::Base.deliveries.size }.by(0)
      end
    end

    describe 'Sending a message with deliver_later' do
      it 'enqueues a job' do 
        expect {
          TestDatabaseMailer.ping(user.email).deliver_later
        }.to have_enqueued_job.on_queue('mailers')
      end

      it 'creates a message' do 
        perform_enqueued_jobs do 
          expect do
            TestDatabaseMailer.ping(user.email).deliver_later
          end.to change{Message.count}.by(1)
        end
      end

      it 'does not send a message' do
        perform_enqueued_jobs do 
          expect do
            TestDatabaseMailer.ping(user.email).deliver_later
          end.to change { ActionMailer::Base.deliveries.size }.by(0)
        end
      end

      it 'running daily messages task sends a message' do
        perform_enqueued_jobs do
          expect do
            TestDatabaseMailer.ping(user.email).deliver_later
            MessageJob.new('daily').perform  
          end.to change { ActionMailer::Base.deliveries.size }.by(1)
        end
      end
    end
  end

end