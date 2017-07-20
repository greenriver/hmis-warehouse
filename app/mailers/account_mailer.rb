class AccountMailer < Devise::Mailer
  default template_path: 'devise/mailer'
  def invitation_instructions(record, action, opts = {})
    opts[:subject] = _('Boston DND Warehouse') + ": Account Activation Instructions"
    super
  end
end