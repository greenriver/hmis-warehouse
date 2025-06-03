
# HUD Lists

* For a new year, copy the previous year_hud_list.json file and modify it
* After changes to the JSON files have been confirmed, please run the following tasks to re-generate dependent code:

```
rails code:generate_hud_lists
rails driver:hmis:generate_graphql_enums['2026']
```
