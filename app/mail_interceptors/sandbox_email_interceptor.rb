###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class SandboxEmailInterceptor
  # Recipients who are always BCC'd when sandbox email mode is on
  RECIPIENTS = ENV['SANDBOX_RECIPIENTS']&.split(',') || []

  RECIPIENT_FIELDS = [:to, :cc, :bcc].freeze

  # Separate from sandbox email mode: any value, including an empty one, turns the filter on
  def self.domain_filter_enabled?
    ENV.key?('SANDBOX_EMAIL_ALLOWED_DOMAINS')
  end

  def self.allowed_domains
    ENV.fetch('SANDBOX_EMAIL_ALLOWED_DOMAINS', '').split(',').map { |domain| domain.strip.downcase }.reject(&:blank?)
  end

  def self.enabled?
    Rails.configuration.sandbox_email_mode || domain_filter_enabled?
  end

  def self.delivering_email(mail)
    # The outer database delivery hands each recipient to ImmediateMailer, which is filtered on its own.
    # Filtering here would drop the in-app messages.
    if domain_filter_enabled? && !mail.delivery_method.is_a?(Mail::DatabaseDelivery)
      removed = RECIPIENT_FIELDS.sum { |field| filter_recipients(mail, field) }
      Rails.logger.info("SandboxEmailInterceptor removed #{removed} recipient(s)") if removed.positive?
      if RECIPIENT_FIELDS.all? { |field| mail.public_send(field).blank? }
        mail.perform_deliveries = false
        return
      end
    end

    return unless Rails.configuration.sandbox_email_mode

    mail.bcc = RECIPIENTS
    return if Rails.env.production?
    return unless mail.delivery_method.is_a?(ApplicationMailer.delivery_methods[:db])

    mail.subject = "#{subject_warning} #{mail.subject.gsub(subject_warning, '')}"
    if mail.multipart?
      html_body = mail.html_part.body.to_s
      text_body = mail.text_part.body.to_s
      mail.html_part = html_body.sub('<body>', "<body><p>#{body_warning}</p>") unless html_body.include?(body_warning)
      mail.text_part = body_warning + "\n\n" + text_body unless text_body.include?(body_warning)
    else
      mail.body = "#{body_warning} #{String(mail.body).sub(body_warning, '')}"
    end
  end

  # Keeps only addresses in the allowed domains, preserving display names.
  # @return [Integer] number of addresses removed
  def self.filter_recipients(mail, field)
    return 0 if mail[field].blank?

    addresses = begin
      mail[field].addrs
    rescue Mail::Field::FieldError
      nil
    end
    if addresses.nil?
      mail[field] = nil
      return 1
    end

    kept = addresses.select { |address| allowed_domains.include?(address.domain&.downcase) }
    mail[field] = kept.map(&:format)
    addresses.size - kept.size
  end
  private_class_method :filter_recipients

  def self.subject_warning
    '[TRAINING]'
  end

  def self.body_warning
    '***This message is for training purposes only, the following information is fictitious and does not represent a real housing opportunity or homeless client.***'
  end
end
