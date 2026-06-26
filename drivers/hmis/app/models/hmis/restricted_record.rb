###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Marks HMIS records as restricted. An active (non-deleted) row indicates the restrictable is restricted.
# Initially only Hmis::Hud::Client is supported; additional types will be added later.
class Hmis::RestrictedRecord < Hmis::HmisBase
  CLIENT_RESTRICTABLE_TYPE = 'Hmis::Hud::Client'

  RESTRICTABLE_TYPES = [CLIENT_RESTRICTABLE_TYPE].freeze

  acts_as_paranoid
  has_paper_trail(
    meta: {
      client_id: ->(r) { r.client_restrictable? ? r.restrictable_id : nil },
    },
  )

  belongs_to :restrictable, polymorphic: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :created_by, class_name: 'Hmis::User'

  validates :restrictable_type, inclusion: { in: RESTRICTABLE_TYPES }
  validate :restrictable_data_source_matches

  scope :for_clients, -> { where(restrictable_type: CLIENT_RESTRICTABLE_TYPE) }

  def client_restrictable?
    restrictable_type == CLIENT_RESTRICTABLE_TYPE
  end

  def self.restricted_client_ids
    for_clients.select(:restrictable_id)
  end

  def self.mark!(restrictable, user:)
    raise ArgumentError, "unsupported restrictable type #{restrictable.class.name}" unless restrictable.is_a?(Hmis::Hud::Client)

    existing = with_deleted.find_by(restrictable: restrictable)
    if existing
      # TODO since we are restoring records, shouldn't we have uniqueness index be more strict? it excludes deleted records
      existing.restore if existing.deleted?
      existing.update!(created_by: user, data_source_id: restrictable.data_source_id)
      return existing
    end

    create!(
      restrictable: restrictable,
      data_source_id: restrictable.data_source_id,
      created_by: user,
    )
  end

  def self.unmark!(restrictable)
    find_by(restrictable: restrictable)&.destroy!
  end

  private def restrictable_data_source_matches
    return unless restrictable && data_source_id

    errors.add(:data_source_id, 'must match restrictable data source') if restrictable.data_source_id != data_source_id
  end
end
