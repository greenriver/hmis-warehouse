###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  class User < CasBase
    self.table_name = :users
    has_one :contact
    has_many :user_roles, dependent: :destroy, inverse_of: :user
    has_many :roles, through: :user_roles
    belongs_to :agency, optional: true

    scope :match_admin, -> do
      joins(:roles).merge(CasAccess::Role.match_admin)
    end

    scope :in_directory, -> do
      current_scope
    end

    def match_admin?
      self.class.match_admin.where(id: id).exists?
    end

    def name_with_email
      "#{name} <#{email}>"
    end

    def name
      "#{first_name} #{last_name}"
    end

    def phone_for_directory
      contact&.cell_phone
    end

    def agency_name
      agency&.name
    end

    def unique_role_names
      user_roles.map { |ur| ur.role.name }.uniq
    end

    def self.text_search(text)
      return none unless text.present?

      query = "%#{text}%"
      where(
        arel_table[:last_name].matches(query).
        or(arel_table[:first_name].matches(query)).
        or(arel_table[:email].matches(query)),
      )
    end
  end
end
