with file_tags as (
  select taggings.taggable_id as file_id,
    array_agg(tags.name) as tag_names
  from tags
    inner join taggings on tags.id = taggings.tag_id
  where taggings.taggable_type = 'GrdaWarehouse::File'
  group by taggings.taggable_id
)
select client_files.id,
  client_files.client_id,
  client_files.visible_in_window,
  client_files.consent_form_signed_on as signature_date,
  client_files.consent_form_confirmed as consent_confirmed,
  client_files.effective_date,
  client_files.expiration_date,
  client_files.coc_codes,
  client_files.url,
  coalesce(ft.tag_names, '{}') as tags,
  client_files.data_source_id,
  client_files.created_at,
  client_files.updated_at
from files client_files
  left join file_tags ft on ft.file_id = client_files.id
where client_files.type = 'GrdaWarehouse::ClientFile'
  and client_files.deleted_at is null
  and client_files.confidential = false
  and client_files.consent_revoked_at is null
