SELECT
  referral.id,
  referral.client_id,
  referral.opportunity_id,
  referral.created_at,
  referral.updated_at,
  referral.completed_at,
  referral.status,
  referral.custom_referral_status_id,
  -- todo: add decline_reason_id
  referral.referred_by_id,
  referral.target_enrollment_id,
  referral.source_enrollment_id,
  referral.referral_origin,
  instance.template_id
FROM ce_referrals referral
LEFT JOIN wfe_instances instance ON instance.id = referral.workflow_instance_id
