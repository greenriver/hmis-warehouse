SELECT
  step.id,
  referral.id AS referral_id,
  node.name,
  step.form_definition_id,
  step.status,
  step.started_at,
  step.completed_at,
  step.created_at,
  step.updated_at,
  step.available_at,
  step.updated_by_id
FROM wfe_steps step
INNER JOIN wfe_instances instance ON instance.id = step.instance_id
INNER JOIN ce_referrals referral ON referral.workflow_instance_id = instance.id
LEFT JOIN wfd_nodes node ON node.id = step.node_id
