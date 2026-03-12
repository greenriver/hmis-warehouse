SELECT
  participant.id,
  participant.referral_id,
  participant.user_id,
  swimlane.name AS swimlane_name,
  participant.created_at,
  participant.updated_at
FROM ce_referral_participants participant
LEFT JOIN wfd_swimlanes swimlane ON swimlane.id = participant.swimlane_id
