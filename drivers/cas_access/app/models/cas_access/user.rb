###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

    def match_admin?
      self.class.match_admin.where(id: id).exists?
    end
  end
end
