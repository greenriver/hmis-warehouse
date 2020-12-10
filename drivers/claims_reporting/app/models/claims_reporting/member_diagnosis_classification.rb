class ClaimsReporting::MemberDiagnosisClassification < HealthBase
  def self.classify(roster: ClaimsReporting::MemberRoster.all)
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
    # prevalence rates estimated from 10 minutes of Googling
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
      coi: rand <= 0.30 ? 1 : 0,
      high_er: rand <= 0.25 ? 1 : 0,
      psychoses: rand <= 0.20 ? 1 : 0,
      other_ip_psych: rand <= 0.13 ? 1 : 0,
      engaged_member_days: engaged_member_days,
      antipsy_denom: antipsy_denom,
      antipsy_day: rand * antipsy_denom,
      antidep_denom: antidep_denom,
      antidep_day: rand * antipsy_denom,
      moodstab_denom: moodstab_denom,
      moodstab_day: rand * antipsy_denom,
    )
  end
end
