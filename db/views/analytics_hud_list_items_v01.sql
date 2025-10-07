select id,
  list_name,
  method_name,
  list_number,
  label,
  code,
  fiscal_year
from hud_list_items
where active = true
