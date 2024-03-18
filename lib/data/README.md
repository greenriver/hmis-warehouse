
## HUD Lists

For a new year, copy the previous year_hud_list.json file and the year_additional_lists directory and then rename them with the new year suffix. Update files in the the year_additional_lists with data from the new specs.

Run the json generator `code:generate_hud_list_json year file_path_to_machinde_readable_xlsx_file`

e.g.
```
rails code:generate_hud_list_json\["2024","lib/data/CSV Specifications Machine-Readable_FY2024.xlsx"\]
```

This will generate the JSON files. To account for some inconsistencies with the excel data, some names will be generated as "Unknown" and will need to be verified manually with the lists specified in the HUD HMIS CSV specifications.

After changes to the JSON files have been confirmed, please run the following tasks to re-generate dependent code:

```
rails code:generate_hud_lists
rails driver:hmis:generate_graphql_enums
```