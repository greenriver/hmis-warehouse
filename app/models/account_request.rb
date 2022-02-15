###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

  def convert_to_user!(user:, role_ids: [], access_group_ids: [])
    options = {
      first_name: first_name,
      last_name: last_name,
      email: email,
      phone: phone,
      agency_id: agency_id,
    }
    user = User.invite!(options, user)
    roles = Role.where(id: role_ids)
    access_groups = AccessGroup.where(id: access_group_ids)
    user.roles = roles
    user.access_groups = access_groups
    update(
      status: :accepted,
      accepted_by: user.id,
      accepted_at: Time.current,
      user_id: user.id,
    )
  end
end
