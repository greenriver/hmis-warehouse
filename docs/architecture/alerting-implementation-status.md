# Alert Configuration System - Implementation Status

**Last Updated:** 2025-10-08
**Related Architecture:** See `alerting.md` for full design documentation

## Current Status: Phase 3 (Code Migration) - Partially Complete

The core infrastructure is deployed and functional. System alert subscriptions are working on the user edit page. Remaining work focuses on extending to organization/project contacts.

---

## ✅ Completed Work

### Database & Models (Phase 1)

#### Migrations Created
All migrations are in `db/warehouse/migrate/`:

1. **`20251008131232_create_alert_definitions.rb`**
   - Creates `alert_definitions` table with column comments
   - Indexes on `code` (unique) and `category`
   - ✅ Status: Deployed

2. **`20251008131833_create_contact_alert_subscriptions.rb`**
   - Creates `contact_alert_subscriptions` join table
   - Unique index on `[contact_id, alert_definition_id]`
   - ✅ Status: Deployed

3. **`20251008141823_seed_initial_alert_definitions.rb`**
   - Seeds 7 initial alert definitions across 3 categories
   - Categories: system, data_quality, client_activity
   - ✅ Status: Deployed

4. **`20251008151928_add_entity_type_to_contacts.rb`**
   - Adds `entity_type` column for proper polymorphic associations
   - Backfills based on STI `type` column
   - Index on `[entity_type, entity_id]`
   - ✅ Status: Deployed

#### Models Created

1. **`app/models/grda_warehouse/alert_definition.rb`**
   - Defines alert types with categories
   - `show_to?(user)` method for permission-based visibility
   - `subscribed_users` method returns User objects subscribed to alert
   - `initial_definitions` with visibility check lambdas
   - ✅ Status: Complete with visibility checks

2. **`app/models/grda_warehouse/contact_alert_subscription.rb`**
   - Join model between contacts and alert definitions
   - Uses explicit `foreign_key: :contact_id, inverse_of:` to avoid Rails inferring wrong FK from Base class
   - Includes `migrate_user_notification_preferences!` class method for data migration
   - ✅ Status: Complete

3. **`app/models/grda_warehouse/contact/user.rb`**
   - New contact type for user-level system alerts
   - `belongs_to :entity, polymorphic: true`
   - ✅ Status: Complete

#### Models Updated

1. **`app/models/grda_warehouse/contact/base.rb`**
   - Added `has_many :contact_alert_subscriptions` with explicit foreign_key
   - Added `has_many :alert_definitions, through: :contact_alert_subscriptions`
   - Added helper methods: `subscribed_to?`, `subscribe_to!`, `unsubscribe_from!`
   - ✅ Status: Complete

2. **`app/models/grda_warehouse/contact/organization.rb`**
   - Added `belongs_to :entity, polymorphic: true`
   - ✅ Status: Complete

3. **`app/models/grda_warehouse/contact/project.rb`**
   - Added `belongs_to :entity, polymorphic: true`
   - ✅ Status: Complete

4. **`app/models/user.rb`**
   - Added `has_many :contacts` association
   - Added `has_one :system_contact` with scope
   - Added `accepts_nested_attributes_for :system_contact`
   - Added `before_validation :set_system_contact_entity` callback
   - Added helper methods: `system_contact!`, `all_alert_subscriptions`, `subscribed_to_system_alert?`, `subscribe_to_system_alert!`
   - ✅ Status: Complete

5. **`app/models/concerns/user_concern.rb`**
   - Added generic `subscribed_to_alert(alert_code)` scope using cross-database-safe subquery pattern
   - Updated existing scopes to use new system:
     - `receives_file_notifications` → calls `subscribed_to_alert('file_upload')`
     - `receives_account_request_notifications` → calls `subscribed_to_alert('account_request')`
     - `receives_new_account_notifications` → calls `subscribed_to_alert('new_account')`
   - Added new scopes for remaining alerts:
     - `notifies_on_vispdat_completed` → calls `subscribed_to_alert('vispdat_completed')`
     - `notifies_on_client_added` → calls `subscribed_to_alert('client_added')`
     - `notifies_on_anomaly_identified` → calls `subscribed_to_alert('anomaly_identified')`
   - ✅ Status: Complete

### Data Migration (Phase 2)

- **TaskQueue Job:** Added to `config/application.rb` as `config.queued_tasks[:migrate_user_notification_preferences]`
- Calls `GrdaWarehouse::AlertDefinition.seed_initial_definitions`
- Calls `GrdaWarehouse::ContactAlertSubscription.migrate_user_notification_preferences!`
- ✅ Status: Configured (needs to be run in production)

### UI Implementation

#### User Edit Page

1. **`app/controllers/admin/users_controller.rb`**
   - Updated `edit` action to build `system_contact` if nil
   - Loads `@system_alerts = GrdaWarehouse::AlertDefinition.system_alerts.active.order(:name)`
   - Updated `user_params` to include `system_contact_attributes: [:id, alert_definition_ids: []]`
   - ✅ Status: Complete

2. **`app/views/admin/users/_form_fields.haml`**
   - Replaced individual notification boolean inputs with loop over system alerts
   - Uses `f.simple_fields_for :system_contact` with nested checkboxes
   - Each alert checkbox uses visibility check: `alert.show_to?(current_user)`
   - Replaces lines 52-64 of original form
   - ✅ Status: Complete

### Code Migration (Phase 3)

#### Mailer Updates

1. **`app/mailers/notify_user.rb`**
   - Updated `vispdat_completed` method: `User.active.notifies_on_vispdat_completed`
   - Updated `client_added` method: `User.active.notifies_on_client_added`
   - Updated `anomaly_identified` method: `User.active.notifies_on_anomaly_identified`
   - Existing methods already using scopes: `pending_account_submitted`, `new_account_created`
   - ✅ Status: Complete

---

## 🔄 In Progress / Blocked

None currently - all assigned work is complete.

---

## ⏳ Remaining Work

### Phase 3: Complete Code Migration

#### 1. Find and Update Any Remaining Direct Column References

**Search for old column usage:**
```bash
# Search for any remaining references to old boolean columns
grep -r "notify_on_new_account" app/
grep -r "receive_file_upload_notifications" app/
grep -r "notify_on_vispdat_completed" app/
grep -r "notify_on_client_added" app/
grep -r "notify_on_anomaly_identified" app/
grep -r "receive_account_request_notifications" app/
```

**Action:** Update any remaining code to use new scopes or subscription checks.

#### 2. Update User Audit History for Alert Subscription Changes

**File:** `app/models/user_edit_history/user_version_change_summary.rb`

**Problem:** The user audit page currently tracks changes to notification boolean columns (lines 42-51 in VISIBLE_FIELDS_VALUES). Now that subscriptions are stored in the `contact_alert_subscriptions` join table (warehouse database), we need to maintain audit visibility of these changes.

**Current audit tracking:**
- `notify_on_anomaly_identified` (line 42)
- `notify_on_client_added` (line 43)
- `notify_on_new_account` (line 44)
- `notify_on_vispdat_completed` (line 45)
- `receive_account_request_notifications` (line 50)
- `receive_file_upload_notifications` (line 51)

**Solution options:**

1. **PaperTrail on ContactAlertSubscription model**
   - Add `has_paper_trail` to `GrdaWarehouse::ContactAlertSubscription`
   - Track subscription create/destroy events separately
   - Display these changes in user audit history by joining versions

2. **Custom change tracking in User save callback**
   - After save, compare old/new alert subscriptions
   - Create custom PaperTrail metadata entry for User version
   - Format changes to match existing audit display

3. **Keep old boolean columns temporarily**
   - Maintain boolean columns as computed/cached values
   - Update columns when subscriptions change
   - Continue using existing audit system until Phase 5 removal

**Action needed:**
1. Review user audit page to understand how version changes are displayed
2. Choose appropriate solution (recommend option 1 for clean separation)
3. Implement PaperTrail tracking on ContactAlertSubscription
4. Update user audit view to show subscription changes alongside user changes
5. Test that subscription changes appear in audit history

**Files to review:**
- `app/models/user_edit_history/user_version_change_summary.rb` (lines 42-51)
- User audit view (likely `app/views/admin/users/edit.haml` or similar)
- Controller that displays audit history

**Priority:** Medium-High - Important for audit trail compliance and admin oversight.

### Phase 3: UI - Organization/Project Contact Forms

#### 3. Add Contact Relationships Summary to User Page (Optional)

**File:** `app/views/admin/users/edit.haml`

Currently commented out on lines 11-13. This would show a read-only summary of all contacts and their alert subscriptions.

**Action:** Implement `app/views/admin/users/_contact_relationships.haml` partial as described in `alerting.md` lines 500-544.

**Priority:** Low - Nice to have, but not required for core functionality.

#### 4. Update Organization Contacts Form

**Files to update:**
- `app/controllers/organizations_contacts_controller.rb` (or similar)
- `app/views/organizations/contacts/_form.haml`

**Changes needed:**
1. Update controller strong parameters to accept `alert_definition_ids: []`
2. Add alert subscription section to form (see `alerting.md` lines 547-582)
3. Show alerts grouped by category (exclude 'system' category)

**Priority:** Medium - Required for organization-level alerts, but system alerts are working.

#### 5. Update Project Contacts Form

**Files to update:**
- `app/controllers/projects_contacts_controller.rb` (or similar)
- `app/views/projects/contacts/_form.haml`

**Changes needed:**
1. Mirror organization form structure
2. Update controller strong parameters to accept `alert_definition_ids: []`
3. Add alert subscription section to form

**Priority:** Medium - Required for project-level alerts, but system alerts are working.

### Phase 4: Deprecation (Future Release)

#### 6. Add Deprecation Warnings to Old Columns

**Migration:** Create `deprecate_user_notification_columns.rb`

Add column comments indicating deprecation (see `alerting.md` lines 365-403).

**Action:** Deploy after Phase 3 is complete and stable in production.

**Priority:** Low - Only after system is proven stable.

### Phase 5: Cleanup (Far Future Release)

#### 7. Remove Old Boolean Columns

**Migration:** Create `remove_deprecated_user_notification_columns.rb`

Drop deprecated columns from `users` table (see `alerting.md` lines 405-432).

**Action:** Only after several releases with no usage of old columns.

**Priority:** Very Low - Only after extended stability period (6+ releases).

---

## 📋 Testing Checklist

### ✅ Completed Testing Areas

- [x] User model associations and helpers
- [x] Contact model associations and helpers
- [x] AlertDefinition model and scopes
- [x] ContactAlertSubscription model
- [x] User scopes in UserConcern
- [x] User edit form displays system alerts
- [x] User edit form saves system alert subscriptions
- [x] Visibility checks work correctly (OKTA, can_edit_vspdat?, etc.)
- [x] Mailer methods use new scopes

### ⏳ Remaining Testing Areas

- [ ] Organization contact form displays and saves alert subscriptions
- [ ] Project contact form displays and saves alert subscriptions
- [ ] Data migration script successfully migrates existing preferences
- [ ] Cross-database query performance is acceptable
- [ ] System tests for complete user workflows
- [ ] Integration tests for organization/project contact workflows

---

## 🔑 Key Technical Decisions

### Cross-Database Query Pattern

**Problem:** Cannot join between primary database (users) and warehouse database (contacts, alerts)

**Solution:** Use subquery pattern with `pluck` to get IDs first:

```ruby
scope :subscribed_to_alert, ->(alert_code) do
  definition = GrdaWarehouse::AlertDefinition.find_by(code: alert_code)
  return none unless definition

  # Get user IDs from warehouse database first
  subscribed_user_ids = GrdaWarehouse::Contact::User.
    joins(:contact_alert_subscriptions).
    merge(GrdaWarehouse::ContactAlertSubscription.where(alert_definition_id: definition.id, active: true)).
    pluck(:entity_id)

  # Then query users table with those IDs
  where(id: subscribed_user_ids)
end
```

### Polymorphic Association Setup

**Problem:** Contacts need to reference User, Organization, or Project entities

**Solution:** Added `entity_type` column to contacts table (separate from STI `type` column):

- `type`: STI class name (e.g., 'GrdaWarehouse::Contact::User')
- `entity_type`: Polymorphic association target (e.g., 'User', 'GrdaWarehouse::Hud::Organization')
- `entity_id`: Polymorphic association foreign key

All Contact subclasses now have `belongs_to :entity, polymorphic: true`.

### Explicit Foreign Key for Contact Associations

**Problem:** Rails infers foreign key as `base_id` from class name `GrdaWarehouse::Contact::Base`

**Solution:** Always specify explicit `foreign_key: :contact_id, inverse_of: :contact_alert_subscriptions` on both sides of association.

### Nested Attributes for System Contact

**Problem:** Need to create/update system_contact when saving user

**Solution:**
1. `accepts_nested_attributes_for :system_contact` in User model
2. `before_validation` callback to set entity attributes
3. Controller builds system_contact if nil before rendering form
4. Strong parameters accept `system_contact_attributes: [:id, alert_definition_ids: []]`

---

## 📚 Key Files Reference

### Models
- `app/models/user.rb` - User model with system_contact association
- `app/models/concerns/user_concern.rb` - User scopes for alert subscriptions
- `app/models/grda_warehouse/alert_definition.rb` - Alert type definitions
- `app/models/grda_warehouse/contact_alert_subscription.rb` - Join model
- `app/models/grda_warehouse/contact/base.rb` - Base contact model
- `app/models/grda_warehouse/contact/user.rb` - User-level contact type
- `app/models/grda_warehouse/contact/organization.rb` - Org-level contact type
- `app/models/grda_warehouse/contact/project.rb` - Project-level contact type

### Controllers
- `app/controllers/admin/users_controller.rb` - User management (✅ updated)
- `app/controllers/organizations_contacts_controller.rb` - Org contacts (⏳ needs update)
- `app/controllers/projects_contacts_controller.rb` - Project contacts (⏳ needs update)

### Views
- `app/views/admin/users/_form_fields.haml` - User form (✅ updated)
- `app/views/admin/users/_contact_relationships.haml` - Summary partial (⏳ not created yet)
- `app/views/organizations/contacts/_form.haml` - Org contact form (⏳ needs update)
- `app/views/projects/contacts/_form.haml` - Project contact form (⏳ needs update)

### Mailers
- `app/mailers/notify_user.rb` - All notification emails (✅ updated)

### Migrations
- `db/warehouse/migrate/20251008131232_create_alert_definitions.rb`
- `db/warehouse/migrate/20251008131833_create_contact_alert_subscriptions.rb`
- `db/warehouse/migrate/20251008141823_seed_initial_alert_definitions.rb`
- `db/warehouse/migrate/20251008151928_add_entity_type_to_contacts.rb`

### Configuration
- `config/application.rb` - TaskQueue job for data migration

### Documentation
- `docs/architecture/alerting.md` - Full architecture and design documentation
- `docs/architecture/alerting-implementation-status.md` - This file

---

## 🚀 How to Resume Work

### Next Immediate Steps

1. **Run data migration in production**
   - Ensure TaskQueue job has run: `config.queued_tasks[:migrate_user_notification_preferences]`
   - Verify existing user notification preferences have been migrated to subscriptions
   - Check for any errors in migration

2. **Update Organization Contacts Form**
   - Find organization contacts controller and views
   - Add alert subscription UI similar to user form
   - Test creating/updating organization contacts with alert subscriptions

3. **Update Project Contacts Form**
   - Find project contacts controller and views
   - Add alert subscription UI similar to organization form
   - Test creating/updating project contacts with alert subscriptions

### Commands to Find Controllers/Views

```bash
# Find organization contacts controller
find app/controllers -name "*organization*contact*"

# Find project contacts controller
find app/controllers -name "*project*contact*"

# Find organization contacts views
find app/views -name "*organization*" -type d | grep contact

# Find project contacts views
find app/views -name "*project*" -type d | grep contact
```

### Testing the Current System

```bash
# Run tests for User model
dcr spec bundle exec rspec spec/models/user_spec.rb

# Run tests for Contact models
dcr spec bundle exec rspec spec/models/grda_warehouse/contact

# Run tests for AlertDefinition
dcr spec bundle exec rspec spec/models/grda_warehouse/alert_definition_spec.rb

# Run tests for user controller
dcr spec bundle exec rspec spec/controllers/admin/users_controller_spec.rb
```

### Verifying in Rails Console

```ruby
# Check alert definitions are seeded
GrdaWarehouse::AlertDefinition.count
# Should return 7

# Check categories
GrdaWarehouse::AlertDefinition.pluck(:category).uniq
# Should return ["system", "data_quality", "client_activity"]

# Find a user and check their system contact
user = User.first
user.system_contact
# May be nil if not created yet

# Create system contact and subscribe to alert
user.subscribe_to_system_alert!('new_account')

# Check subscription
user.subscribed_to_system_alert?('new_account')
# Should return true

# Test scope
User.receives_new_account_notifications.count
# Should return count of users subscribed to new_account alert
```

---

## ⚠️ Known Issues / Gotchas

1. **Cross-database joins don't work** - Always use subquery pattern with `pluck` when querying across primary and warehouse databases

2. **Contact::Base foreign key inference** - Rails infers `base_id` instead of `contact_id` - always specify explicit `foreign_key: :contact_id, inverse_of:`

3. **System contact creation** - Must set all entity attributes before validation:
   ```ruby
   system_contact.entity_type = 'User'
   system_contact.entity_id = id
   system_contact.user_id = id
   system_contact.type = 'GrdaWarehouse::Contact::User'
   ```

4. **Old boolean columns still exist** - Don't remove them yet! They're needed for rollback safety and gradual migration.

5. **Visibility checks are permission-based** - Some alerts only show if user has certain permissions or env vars are set (OKTA_DOMAIN, can_edit_vspdat?, authoritative data source exists)

---

## 📞 Questions for User

Before resuming work, consider asking:

1. Should we prioritize organization/project contact forms, or are system alerts sufficient for now?
2. Has the data migration TaskQueue job been run in production yet?
3. Are there any additional alert types needed beyond the initial 7?
4. Do we want the contact relationships summary on the user page (currently commented out)?
5. Should we add any additional delivery preferences (email vs. in-app, digest frequency)?
