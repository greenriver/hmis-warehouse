###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SandboxEmailInterceptor do
  around do |example|
    original = ENV.fetch('SANDBOX_EMAIL_ALLOWED_DOMAINS', nil)
    example.run
  ensure
    ENV['SANDBOX_EMAIL_ALLOWED_DOMAINS'] = original
  end

  def build_mail(to: nil, carbon: nil, bcc: nil)
    Mail.new(from: 'sender@example.org', to: to, cc: carbon, bcc: bcc, subject: 'Hello', body: 'Body')
  end

  describe '.allowed_domains' do
    it 'splits on commas, trims, downcases, and drops blanks' do
      ENV['SANDBOX_EMAIL_ALLOWED_DOMAINS'] = ' Example.org, partner.GOV ,,'

      expect(described_class.allowed_domains).to eq(['example.org', 'partner.gov'])
    end
  end

  describe '.enabled?' do
    it 'is true when only the allowed domains are set' do
      ENV['SANDBOX_EMAIL_ALLOWED_DOMAINS'] = 'example.org'
      allow(Rails.configuration).to receive(:sandbox_email_mode).and_return(false)

      expect(described_class.enabled?).to be(true)
    end

    it 'is true when only sandbox email mode is on' do
      ENV.delete('SANDBOX_EMAIL_ALLOWED_DOMAINS')
      allow(Rails.configuration).to receive(:sandbox_email_mode).and_return(true)

      expect(described_class.enabled?).to be(true)
    end

    it 'is false when neither is set' do
      ENV.delete('SANDBOX_EMAIL_ALLOWED_DOMAINS')
      allow(Rails.configuration).to receive(:sandbox_email_mode).and_return(false)

      expect(described_class.enabled?).to be(false)
    end
  end

  describe '.delivering_email domain filter' do
    before { ENV['SANDBOX_EMAIL_ALLOWED_DOMAINS'] = 'example.org, Partner.gov' }

    it 'keeps allowed recipients in each field and removes the rest' do
      mail = build_mail(to: ['a@example.org', 'b@other.com'], carbon: ['c@partner.gov'], bcc: ['d@evil.net'])

      described_class.delivering_email(mail)

      expect(mail.to).to eq(['a@example.org'])
      expect(mail.cc).to eq(['c@partner.gov'])
      expect(mail.bcc).to be_blank
      expect(mail.perform_deliveries).to be(true)
    end

    it 'matches case-insensitively and keeps the display name' do
      mail = build_mail(to: 'Jane <JANE@Example.ORG>')

      described_class.delivering_email(mail)

      expect(mail[:to].addrs.map { |addr| [addr.display_name, addr.address.downcase] }).to eq([['Jane', 'jane@example.org']])
    end

    it 'does not allow a subdomain of an allowed domain' do
      mail = build_mail(to: ['a@mail.example.org', 'b@example.org'])

      described_class.delivering_email(mail)

      expect(mail.to).to eq(['b@example.org'])
    end

    it 'drops an address without a domain' do
      mail = build_mail(to: ['nobody', 'b@example.org'])

      described_class.delivering_email(mail)

      expect(mail.to).to eq(['b@example.org'])
    end

    it 'cancels delivery when every recipient is outside the allowed domains' do
      mail = build_mail(to: ['a@other.com'], carbon: ['b@evil.net'])

      described_class.delivering_email(mail)

      expect(mail.perform_deliveries).to be(false)
      expect(mail.to).to be_blank
    end

    it 'cancels delivery when no domain is allowed' do
      ENV['SANDBOX_EMAIL_ALLOWED_DOMAINS'] = ''
      mail = build_mail(to: ['a@example.org'])

      described_class.delivering_email(mail)

      expect(mail.perform_deliveries).to be(false)
    end

    it 'logs the number removed without logging addresses' do
      messages = []
      allow(Rails.logger).to receive(:info) { |message| messages << message.to_s }
      mail = build_mail(to: ['a@example.org', 'b@other.com'], carbon: ['c@evil.net'])

      described_class.delivering_email(mail)

      expect(messages).to include('SandboxEmailInterceptor removed 2 recipient(s)')
      expect(messages.join).not_to match(/other\.com|evil\.net/)
    end

    it 'clears a field that cannot be parsed and cancels delivery when nothing is left' do
      mail = build_mail(to: 'a@example.org, @@@')

      expect { described_class.delivering_email(mail) }.not_to raise_error

      expect(mail[:to]).to be_nil
      expect(mail.perform_deliveries).to be(false)
    end

    it 'clears an unparseable field but delivers to the other fields' do
      mail = build_mail(to: 'a@example.org, @@@', carbon: ['b@example.org'])

      described_class.delivering_email(mail)

      expect(mail[:to]).to be_nil
      expect(mail.cc).to eq(['b@example.org'])
      expect(mail.perform_deliveries).to be(true)
    end

    it 'leaves a mail alone when it is destined for database delivery' do
      mail = build_mail(to: ['a@other.com'])
      mail.delivery_method(Mail::DatabaseDelivery, {})

      described_class.delivering_email(mail)

      expect(mail.to).to eq(['a@other.com'])
      expect(mail.perform_deliveries).to be(true)
    end
  end

  describe '.delivering_email with the domain filter and sandbox email mode' do
    let(:sandbox_recipient) { 'monitor@sandbox-recipients.test' }

    before do
      ENV['SANDBOX_EMAIL_ALLOWED_DOMAINS'] = 'example.org'
      allow(Rails.configuration).to receive(:sandbox_email_mode).and_return(true)
      stub_const('SandboxEmailInterceptor::RECIPIENTS', [sandbox_recipient])
    end

    it 'strips disallowed recipients from to and cc and replaces bcc on a real transport' do
      mail = build_mail(to: ['a@example.org', 'b@other.com'], carbon: ['c@evil.net'], bcc: ['d@example.org'])

      described_class.delivering_email(mail)

      expect(mail.to).to eq(['a@example.org'])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to eq([sandbox_recipient])
      expect(mail.perform_deliveries).to be(true)
    end

    it 'cancels delivery and leaves bcc unset when every recipient is disallowed' do
      mail = build_mail(to: ['a@other.com'], carbon: ['b@evil.net'])

      described_class.delivering_email(mail)

      expect(mail.perform_deliveries).to be(false)
      expect(mail.bcc).to be_blank
    end

    it 'skips the filter, replaces bcc, and prefixes the subject on database delivery' do
      mail = build_mail(to: ['a@example.org', 'b@other.com'], bcc: ['d@example.org'])
      mail.delivery_method(Mail::DatabaseDelivery, {})

      described_class.delivering_email(mail)

      expect(mail.to).to eq(['a@example.org', 'b@other.com'])
      expect(mail.bcc).to eq([sandbox_recipient])
      expect(mail.subject).to eq('[TRAINING] Hello')
    end
  end

  describe '.delivering_email without the allow-list' do
    it 'leaves recipients and bcc unchanged when neither switch is on' do
      ENV.delete('SANDBOX_EMAIL_ALLOWED_DOMAINS')
      allow(Rails.configuration).to receive(:sandbox_email_mode).and_return(false)
      mail = build_mail(to: ['a@other.com'], carbon: ['b@evil.net'], bcc: ['c@elsewhere.org'])

      described_class.delivering_email(mail)

      expect(mail.to).to eq(['a@other.com'])
      expect(mail.cc).to eq(['b@evil.net'])
      expect(mail.bcc).to eq(['c@elsewhere.org'])
    end
  end

  describe 'delivery through a database mailer' do
    let(:mailer_class) do
      Class.new(DatabaseMailer) do
        def self.name
          'SandboxSpecMailer'
        end

        def hello(recipients)
          mail(to: recipients, subject: 'Hello', body: 'Body')
        end
      end
    end

    let!(:allowed_user) { create(:user, email: 'ok-user@example.org') }
    let!(:blocked_user) { create(:user, email: 'blocked-user@other.com') }

    before do
      ENV['SANDBOX_EMAIL_ALLOWED_DOMAINS'] = 'example.org'
      ActionMailer::Base.register_interceptor(described_class)
      ActionMailer::Base.deliveries.clear
    end

    after { ActionMailer::Base.unregister_interceptor(described_class) }

    it 'keeps in-app messages for every user but emails only allowed addresses' do
      recipients = [allowed_user.email, blocked_user.email, 'contact@example.org', 'contact@other.com']

      expect { mailer_class.hello(recipients).deliver_now }.to change { Message.where(user_id: [allowed_user.id, blocked_user.id]).count }.by(2)

      expect(ActionMailer::Base.deliveries.flat_map(&:to)).to contain_exactly(allowed_user.email, 'contact@example.org')
      expect(Message.where(user_id: blocked_user.id).count).to eq(1)
    end
  end
end
