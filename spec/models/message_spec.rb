###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  include ActiveJob::TestHelper
  describe '#sanitized_body' do
    let(:html_message) do
      create(
        :message,
        body: '<html><head></head><body><a href="#" onclick="runBadCode()">Click Me</a> <span class="highlight">Text</span></body></html>',
        html: true,
      )
    end
    let(:text_message) do
      create(
        :message,
        body: '<a href="#" onclick="runBadCode()">Click Me</a> <span class="highlight">Text</span></body>',
        html: false,
      )
    end

    describe 'text format' do
      it 'returns raw unescaped body for text message' do
        result = text_message.sanitized_body(render_as: :text)
        expect(result).to eq(text_message.body)
        expect(result).not_to be_html_safe
      end

      it 'returns safe text from html message' do
        result = html_message.sanitized_body(render_as: :text)
        expect(result).to eq('Click Me Text')
        expect(result).not_to be_html_safe
      end
    end

    describe 'html format' do
      it 'returns stripped sanitized html from text message' do
        result = text_message.sanitized_body(render_as: :html)
        expect(result).to eq('<p>Click Me Text</p>')
        expect(result).to be_html_safe
      end

      it 'returns sanitized html from html message' do
        result = html_message.sanitized_body(render_as: :html)
        expect(result).to eq('<a href="#">Click Me</a> <span class="highlight">Text</span>')
        expect(result).to be_html_safe
      end

      it 'makes urls clickable for text messages' do
        url = 'http://example.com?a=1&b=2'
        text_message.body = "hello #{url}"
        result = text_message.sanitized_body(render_as: :html)
        escaped_url = 'http://example.com?a=1&amp;b=2'
        expect(result).to eq("<p>hello <a href=\"#{escaped_url}\">#{escaped_url}</a></p>")
        expect(result).to be_html_safe
      end
    end
  end

  describe 'When user email schedule set to immediate: ' do
    let!(:user) { create :user, email: 'noreply-for-testing@greenriver.com', email_schedule: 'immediate' }

    describe 'Sending a message with deliver_now' do
      it 'creates a message' do
        expect do
          TestDatabaseMailer.ping(user.email).deliver_now
        end.to change { Message.count }.by(1)
      end

      it 'sends a message' do
        expect do
          TestDatabaseMailer.ping(user.email).deliver_now
        end.to change { ActionMailer::Base.deliveries.size }.by(1)
      end
    end

    describe 'Sending a message with deliver_later' do
      it 'enqueues a job' do
        expect do
          TestDatabaseMailer.ping(user.email).deliver_later
        end.to have_enqueued_job.on_queue('mailers')
      end

      it 'creates a message' do
        perform_enqueued_jobs do
          expect do
            TestDatabaseMailer.ping(user.email).deliver_later
          end.to change { Message.count }.by(1)
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
    let!(:user) { create :user, email: 'noreply-for-testing@greenriver.com', email_schedule: 'daily' }

    describe 'Sending a message with deliver_now' do
      it 'creates a message' do
        expect do
          TestDatabaseMailer.ping(user.email).deliver_now
        end.to change { Message.count }.by(1)
      end

      it 'does not send a message' do
        expect do
          TestDatabaseMailer.ping(user.email).deliver_now
        end.to change { ActionMailer::Base.deliveries.size }.by(0)
      end
    end

    describe 'Sending a message with deliver_later' do
      it 'enqueues a job' do
        expect do
          TestDatabaseMailer.ping(user.email).deliver_later
        end.to have_enqueued_job.on_queue('mailers')
      end

      it 'creates a message' do
        perform_enqueued_jobs do
          expect do
            TestDatabaseMailer.ping(user.email).deliver_later
          end.to change { Message.count }.by(1)
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
