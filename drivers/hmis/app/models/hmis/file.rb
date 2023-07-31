###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::File < GrdaWarehouse::File
  include ClientFileBase

  acts_as_taggable

  # These are not used, they're here so that we won't get an error trying to get/set the data source
  attr_accessor :data_source_id
  def data_source
    nil
  end

  SORT_OPTIONS = [
    :date_created,
    :date_updated,
  ].freeze

  self.table_name = :files

  belongs_to :enrollment, class_name: '::Hmis::Hud::Enrollment', optional: true
  belongs_to :client, class_name: '::Hmis::Hud::Client'
  belongs_to :user, class_name: 'Hmis::User', optional: true
  belongs_to :updated_by, class_name: 'Hmis::User', optional: true

  scope :with_owner, ->(user) do
    where(user_id: user.id)
  end

  scope :confidential, -> { where(confidential: true) }
  scope :nonconfidential, -> { where(confidential: [false, nil]) }

  scope :viewable_by, ->(user) do
    view_scope = where(client_id: Hmis::Hud::Client.with_access(user, :can_view_any_nonconfidential_client_files, :can_view_any_confidential_client_files))
    # view_scope = view_scope.nonconfidential unless user.can_view_any_confidential_client_files?
    edit_scope = user.can_manage_own_client_files? ? where(user_id: user.id) : none

    view_scope.or(edit_scope)
  end

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :date_created
      order(arel_table[:created_at].desc.nulls_last)
    when :date_updated
      order(arel_table[:updated_at].desc.nulls_last)
    else
      raise NotImplementedError
    end
  end

  def self.authorize_proc
    ->(entity_base, user) do
      # If the entity_base is a file, we're authorizing someone to edit an existing file.
      if entity_base.is_a?(Hmis::File)
        file = entity_base
        client = file.client
      # If the entity_base is a client, that means we're trying to authorize the
      # creation if a new file. (SubmitForm defines the permission base to use)
      elsif entity_base.is_a?(Hmis::Hud::Client)
        client = entity_base
      else
        raise "Unexpected entity base for file permissions: #{entity_base&.class}"
      end

      # file can be created/edited if user has can_manage_any_client_files for the client
      return true if user.can_manage_any_client_files_for?(client)

      # file can be created if user has can_manage_own_client_files for the client
      return true if user.can_manage_own_client_files_for?(client) && file.nil?

      # file can be edited if user has can_manage_own_client_files for the client,
      # AND this user uploaded the file
      return true if user.can_manage_own_client_files_for?(client) && file.user_id == user.id

      false
    end
  end
end
