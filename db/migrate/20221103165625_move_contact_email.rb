class MoveContactEmail < ActiveRecord::Migration[6.1]
  def up
    return unless GrdaWarehouse::Config.get(:support_contact_email).present?

    Link.create(
      location: :footer,
      url: GrdaWarehouse::Config.get(:support_contact_email),
      label: _('Contact Support'),
      subject:  "#{_('Boston DND Warehouse')} Support Request",
    )
  end
end
