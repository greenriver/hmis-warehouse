###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Classify members based on their medical/rx claim history
class ClaimsReporting::MemberDiagnosisClassification < HealthBase
  def self.classify(roster: ClaimsReporting::MemberRoster.all)
    # TODO: Pass in an acceptable claim date range
    # Since most of the classifications are inferred
    # from claim history and are based on counts
    # of the number of events. Events to far back in
    # time should no longer influence the classifier.
    transaction do
      delete_all
      roster.in_batches.map do |batch|
        diags = batch.map do |r|
          fake(member_id: r.member_id)
        end
        import! diags
      end
    end
    nil
  ensure
    PaperTrail.request.enable_model(self)
  end

  def self.fake(member_id:)
    # totally random
    antipsy_denom = rand(365)
    antidep_denom = rand(365)
    moodstab_denom = rand(365)
    engaged_member_days = rand(365)

    # prevalence rates estimated from 10 minutes of Goggling
    # US Homeless population prevalence
    new(
      member_id: member_id,
      currently_assigned: rand <= 0.8 ? 1 : 0,
      currently_engaged: rand <= 0.6 ? 1 : 0,
      ast: rand <= 0.08 ? 1 : 0,
      cpd: rand <= 0.05 ? 1 : 0,
      cir: rand <= 0.33 ? 1 : 0,
      dia: rand <= 0.08 ? 1 : 0,
      spn: rand <= 0.20 ? 1 : 0,
      gbt: rand <= 0.33 ? 1 : 0,
      obs: rand <= 0.44 ? 1 : 0,
      hyp: rand <= 0.35 ? 1 : 0,
      hep: rand <= 0.01 ? 1 : 0,
      sch: rand <= 0.15 ? 1 : 0,
      pbd: rand <= 0.21 ? 1 : 0,
      das: rand <= 0.30 ? 1 : 0,
      pid: rand <= 0.23 ? 1 : 0,
      sia: rand <= 0.65 ? 1 : 0,
      sud: rand <= 0.40 ? 1 : 0,
      other_bh: rand <= 0.10 ? 1 : 0,
      coi: rand <= 0.30 ? 1 : 0,
      high_util: rand <= 0.10 ? 1 : 0,
      high_er: rand <= 0.25 ? 1 : 0,
      psychoses: rand <= 0.20 ? 1 : 0,
      other_ip_psych: rand <= 0.13 ? 1 : 0,
      ip_admits: (ip_admits = rand(2)),
      ip_admits_psychoses: [ip_admits - 1, 0].max,
      er_visits: rand(8),
      engaged_member_days: engaged_member_days,
      # not sure how fractional months will be counted yet
      engaged_member_months: (engaged_member_days / 30.437),
      antipsy_denom: antipsy_denom,
      antipsy_day: rand * antipsy_denom,
      antidep_denom: antidep_denom,
      antidep_day: rand * antipsy_denom,
      moodstab_denom: moodstab_denom,
      moodstab_day: rand * antipsy_denom,
    )
  end
end
