###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AccountRequest < ApplicationRecord
  belongs_to :user, optional: true
  attr_accessor :agency_id, :access_group_ids, :role_ids

  validates :email, presence: true, uniqueness: true, email_format: { check_mx: true }, length: { maximum: 250 }, on: :create
  validates :last_name, presence: true, length: { maximum: 40 }
  validates :first_name, presence: true, length: { maximum: 40 }
  validates_presence_of :details

  scope :requested, -> do
    where(status: :requested)
  end

  scope :accepted, -> do
    where(status: :accepted)
  end

  scope :rejected, -> do
    where(status: :rejected)
  end

  def name
    "#{first_name} #{last_name}"
  end

  def convert_to_user!(user:, role_ids: [], access_group_ids: [], access_control_ids: [])
    options = {
      first_name: first_name,
      last_name: last_name,
      email: email,
      phone: phone,
      agency_id: agency_id,
      active: true,
      confirmed_at: Time.current,
    }
    new_user = User.create!(options)
    # TODO: START_ACL remove when ACL transition complete
    roles = Role.where(id: role_ids)
    access_groups = AccessGroup.where(id: access_group_ids)
    new_user.legacy_roles = roles
    new_user.access_groups = access_groups
    # END_ACL
    acls = AccessControl.where(id: access_control_ids)
    acls.each do |acl|
      acl.user_group.add(new_user)
    end
    update(
      status: :accepted,
      accepted_by: user.id,
      accepted_at: Time.current,
      user_id: new_user.id,
    )
  end
end
