module GrdaWarehouse::Youth
  class YouthReferral < GrdaWarehouseBase
    include ArelHelper
    has_paper_trail
    acts_as_paranoid

    scope :ordered, -> do
      order(referred_on: :desc)
    end

    scope :visible_by?, -> (user) do
      if user.can_edit_anything_super_user?
        all
      # If you can see any, then show yours and those for anyone with a full release
      elsif user.can_view_youth_intake? || user.can_edit_youth_intake?
        joins(:client).where(
          c_t[:id].in(Arel.sql(GrdaWarehouse::Hud::Client.full_housing_release_on_file.select(:id).to_sql)).
          or(arel_table[:user_id].eq(user.id))
        )
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
      ].sort.freeze
    end
  end
end