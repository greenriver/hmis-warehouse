###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Youth
  class YouthReferral < GrdaWarehouseBase
    include ArelHelper
    has_paper_trail
    acts_as_paranoid

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :youth_referrals

    validates_presence_of :referred_on, :referred_to

    attr_accessor :other

    scope :ordered, -> do
      order(referred_on: :desc)
    end

    scope :between, -> (start_date:, end_date:) do
      at = arel_table
      where(at[:referred_on].gteq(start_date).and(at[:referred_on].lteq(end_date)))
    end

    scope :visible_by?, -> (user) do
      # users at your agency, plus your own user in case you have no agency.
      agency_user_ids = User.
        with_deleted.
        where.not(agency_id: nil).
        where(agency_id: user.agency_id).
        pluck(:id) + [user.id]
      if user.can_edit_anything_super_user?
        all
      # If you can see any, then show yours, those for your agency, and those for anyone with a full release
      elsif user.can_view_youth_intake? || user.can_edit_youth_intake?
        where(
          arel_table[:client_id].in(Arel.sql(GrdaWarehouse::Hud::Client.full_housing_release_on_file.select(:id).to_sql)).
          or(arel_table[:user_id].in(agency_user_ids))
        )
      # If you can see your agancy's, then show yours and those for your agency
      elsif user.can_view_own_agency_youth_intake? || user.can_edit_own_agency_youth_intake?
        where(user_id: agency_user_ids)
      else
        none
      end
    end

    def available_referrals
      @available_referrals ||= [
        'Referred for health services',
        'Referred for mental health services',
        'Referred for substance use services',
        'Referred for employment & job training services',
        'Referred for education services',
        'Referred for parenting services',
        'Referred for domestic violence-related services',
        'Referred for lifeskills / financial literacy services',
        'Referred for legal services',
        'Referred for language-related services',
        'Referred for housing supports (include housing supports provided with no-EOHHS funding including housing search)',
        'Referred to Benefits providers (SNAP, SSI, WIC, etc.)',
        'Referred to health insurance providers',
        'Referred to other state agencies (DMH, DDS, etc.)',
        'Referred to cultural / recreational activities',
        'Referred to other services / activities not listed above',
      ].sort.freeze + ['Other']
    end
  end
end