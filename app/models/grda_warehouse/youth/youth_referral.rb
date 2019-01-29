module GrdaWarehouse::Youth
  class YouthReferral < GrdaWarehouseBase
    has_paper_trail
    acts_as_paranoid

    def self.available_referrals
      [
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
      ]
    end
  end
end