###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Marks HMIS records as restricted. An active (non-deleted) row indicates the restrictable is restricted.
# Initially only Hmis::Hud::Client is supported; additional types will be added later.
#
# See docs/features/hmis/hmis-restricted-records.md for more details.
class Hmis::RestrictedRecord < Hmis::HmisBase
  CLIENT_RESTRICTABLE_TYPE = 'Hmis::Hud::Client'

  RESTRICTABLE_TYPES = [CLIENT_RESTRICTABLE_TYPE].freeze

  acts_as_paranoid
  has_paper_trail(
    meta: {
      client_id: ->(r) { r.client_record? ? r.restrictable_id : nil },
    },
  )

  belongs_to :restrictable, polymorphic: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :created_by, class_name: 'Hmis::User'

  validates :restrictable_type, inclusion: { in: RESTRICTABLE_TYPES }
  validate :restrictable_data_source_matches

  scope :for_clients, -> { where(restrictable_type: CLIENT_RESTRICTABLE_TYPE) }

  def client_record?
    restrictable_type == CLIENT_RESTRICTABLE_TYPE
  end

  def self.mark!(record, user:)
    raise ArgumentError, "unsupported restrictable type #{record.class.name}" unless RESTRICTABLE_TYPES.include?(record.class.name)

    # Leave an active restriction alone rather than reassigning created_by, which would put a
    # change on the audit trail that no user actually performed. Matched on restrictable alone,
    # the same way as the unique index that would reject the create! below.
    existing = find_by(restrictable: record)
    return existing if existing

    # Each restriction gets its own row, even if this record was restricted before. Reviving a
    # soft-deleted row instead would leave the new restriction unauditable, because Paranoia's
    # restore writes through update_columns and skips PaperTrail. The unique index is scoped to
    # deleted_at IS NULL, so a restrictable has at most one active row but any number of
    # soft-deleted ones; lookups through with_deleted must expect more than one.
    create!(
      restrictable: record,
      data_source_id: record.data_source_id,
      created_by: user,
    )
  end

  def self.unmark!(record)
    find_by(restrictable: record)&.destroy!
  end

  private def restrictable_data_source_matches
    return unless restrictable && data_source_id

    errors.add(:data_source_id, 'must match restrictable data source') if restrictable.data_source_id != data_source_id
  end
end
