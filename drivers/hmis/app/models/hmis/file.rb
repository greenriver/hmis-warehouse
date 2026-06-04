###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::File < GrdaWarehouse::File
  include ClientFileBase
  include ::Hmis::Hud::Concerns::FormSubmittable
  has_paper_trail(
    meta: {
      enrollment_id: :enrollment_id,
      client_id: :client_id,
      project_id: ->(r) { r.enrollment&.project&.id },
    },
  )

  acts_as_taggable

  # Warehouse files use `data_source_id`; HMIS files are always tied to a HUD Client record, so they don't persist `data_source_id`.
  # These stubs exist so shared warehouse code can read/write the attribute without error.
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
  has_one :custom_data_element, class_name: 'Hmis::Hud::CustomDataElement', foreign_key: 'value_file_id', inverse_of: :value_file

  scope :with_owner, ->(user) do
    where(user_id: user.id)
  end

  scope :confidential, -> { where(confidential: true) }
  scope :nonconfidential, -> { where(confidential: [false, nil]) }

  # Passing client_ids can significantly improve performance, to avoid a subquery on the entire Client table.
  # This may not be the perfect solution (combining scopes would be neater) but it works.
  # It is similar to the strategy described in the Warehouse's EnrollmentArbiter.
  scope :viewable_by, ->(user, client_ids: nil) do
    # NOTE: it's okay that confidential files are included in this scope even if the user
    # doesn't have permission to read the file. Users can see the existence of confidential
    # files but they can't read them. Reference: https://github.com/open-path/Green-River/issues/5184

    client_scope = Hmis::Hud::Client.files_viewable_by(user)
    client_scope = client_scope.where(id: client_ids) if client_ids.present?

    enrollment_scope = Hmis::Hud::Enrollment.files_viewable_by(user)
    enrollment_scope = enrollment_scope.joins(:client).where(c_t[:id].in(client_ids)) if client_ids.present?

    case_statement = Arel::Nodes::Case.new.
      when(arel_table[:enrollment_id].not_eq(nil)).
      then(arel_table[:enrollment_id].in(enrollment_scope.select(:id).arel)).
      else(arel_table[:client_id].in(client_scope.select(:id).arel))

    viewable_scope = Hmis::File.
      left_outer_joins(:client).
      left_outer_joins(:enrollment).
      where(case_statement)

    # Users can see files they uploaded if they have can_manage_own_client_files, even if they lack broader permissions.
    # can_manage_own_client_files is a global permission. If you have it anywhere in the data source,
    # you can manage your own files on any client you can view (even if you don't have it in any of that client's projects).
    if user.policy_for(Hmis::File, policy_type: :hmis_file).can_manage_own_client_files?
      own_scope = Hmis::File.
        left_outer_joins(:client). # same left_outer_joins as above, in order to pass structurally compatible relationship to #or
        left_outer_joins(:enrollment).
        merge(Hmis::Hud::Client.viewable_by(user)).
        where(user_id: user.id)
      viewable_scope = viewable_scope.or(own_scope)
    end

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
end
