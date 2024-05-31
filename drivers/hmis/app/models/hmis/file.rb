###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::File < GrdaWarehouse::File
  include ClientFileBase
  include ::Hmis::Hud::Concerns::HasCustomDataElements
  has_paper_trail(
    meta: {
      enrollment_id: :enrollment_id,
      client_id: :client_id,
      project_id: ->(r) { r.enrollment&.project&.id },
    },
  )

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
    # NOTE: it's okay that confidential files are included in this scope even if the user
    # doesn't have permission to read the file. Users can see the existence of confidential
    # files but they can't read them. Reference:
    # https://www.pivotaltracker.com/n/projects/2591838/stories/185293913
    client_scope = Hmis::Hud::Client.
      viewable_by(user).
      with_access(user, :can_view_any_nonconfidential_client_files, :can_view_any_confidential_client_files)
    enrollment_scope = Hmis::Hud::Enrollment.
      viewable_by(user).
      with_access(user, :can_view_any_nonconfidential_client_files, :can_view_any_confidential_client_files)

    case_statement = Arel::Nodes::Case.new.
      when(arel_table[:enrollment_id].not_eq(nil)).
      then(arel_table[:enrollment_id].in(enrollment_scope.select(:id).arel)).
      else(arel_table[:client_id].in(client_scope.select(:id).arel))

    viewable_scope = Hmis::File.
      left_outer_joins(:client).
      left_outer_joins(:enrollment).
      where(case_statement)

    viewable_scope = viewable_scope.or(Hmis::File.where(user_id: user.id)) if user.can_manage_own_client_files?

    where(id: viewable_scope.select(:id))
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
      case entity_base
      when Hmis::File
        file = entity_base
        client = file.client
      # If the entity_base is a client, that means we're trying to authorize the
      # creation of a new file. (SubmitForm defines the permission base to use)
      when Hmis::Hud::Client
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
