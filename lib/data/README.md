
## HUD Lists

The HUD Lists JSON files are written by hand. They match the lists specified in the HUD HMIS CSV specifications.

When making any changes to the JSON files, please run the following tasks to re-generate dependent code:

```
rails code:generate_hud_lists
rails driver:hmis:generate_graphql_enums
```