###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AccountRequest < ApplicationRecord
  belongs_to :user, optional: true
  attr_accessor :agency_id

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

  def convert_to_user!(user:)
    options = {
      first_name: first_name,
      last_name: last_name,
      email: email,
      phone: phone,
      agency_id: agency_id,
    }
    user = User.invite!(options, user)
    update(
      status: :accepted,
      accepted_by: user.id,
      accepted_at: Time.current,
      user_id: user.id,
    )
  end
end