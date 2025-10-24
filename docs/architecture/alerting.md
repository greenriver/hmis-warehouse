# Alert Configuration System - Architecture Plan

## Overview

This document outlines the design and implementation plan for a comprehensive, extensible alerting system that consolidates existing notification preferences and provides a framework for future alert types.

## Goals

1. Replace disparate boolean notification flags with a unified subscription system
2. Support alerts at multiple scopes: system-wide, organization-level, and project-level
3. Make alert types extensible without code changes
4. Provide clear UI for managing alert subscriptions
5. Maintain backward compatibility during migration

## Data Model Architecture

### Alert Definitions Table (`alert_definitions`)

Stores the catalog of available alert types. Uses `alert_definitions` instead of `alert_types` to avoid Rails STI keyword collision.

**Schema:**
```ruby
create_table :alert_definitions do |t|
  t.string :code, null: false           # Unique identifier (e.g., 'new_account')
  t.string :name, null: false           # Display name (e.g., 'New Account Creation')
  t.string :category, null: false       # Grouping category (e.g., 'system', 'data_quality')
  t.text :description                   # Human-readable description
  t.boolean :active, default: true      # Enable/disable without deletion
  t.timestamps
end

add_index :alert_definitions, :code, unique: true
add_index :alert_definitions, :category
```

**Categories:**
- `system` - System-wide administrative alerts (account creation, file uploads)
- `data_quality` - Data quality reports and anomalies
- `client_activity` - Client-related events (VI-SPDAT, new clients)
- `enrollment` - Enrollment milestones and thresholds
- `administrative` - Administrative tasks and requests

### Contact Alert Subscriptions Table (`contact_alert_subscriptions`)

Join table linking contacts (organization, project, or user) to alert definitions.

**Schema:**
```ruby
create_table :contact_alert_subscriptions do |t|
  t.references :contact, null: false, foreign_key: true
  t.references :alert_definition, null: false, foreign_key: true
  t.boolean :active, default: true      # Enable/disable subscription
  t.timestamps
end

add_index :contact_alert_subscriptions,
  [:contact_id, :alert_definition_id],
  unique: true,
  name: 'index_contact_alerts_on_contact_and_definition'
```

### Contact Types and Scoping

The existing `contacts` table supports polymorphic associations through `entity_type` and `entity_id`. We'll leverage this for three alert scopes:

1. **User-Level Alerts** (`entity_type: 'User'`, `entity_id: user.id`)
   - System-wide notifications (account creation, file uploads, account requests)
   - Managed on user edit page
   - One contact record per user for system alerts

2. **Organization-Level Alerts** (`entity_type: 'GrdaWarehouse::Hud::Organization'`)
   - Alerts specific to organization operations
   - Managed on organization contacts page
   - Multiple contacts possible per organization

3. **Project-Level Alerts** (`entity_type: 'GrdaWarehouse::Hud::Project'`)
   - Alerts specific to project operations
   - Managed on project contacts page
   - Multiple contacts possible per project

## Model Changes

### `GrdaWarehouse::Contact::Base`

**Location:** `app/models/grda_warehouse/contact/base.rb`

**New associations:**
```ruby
has_many :contact_alert_subscriptions,
  dependent: :destroy
has_many :alert_definitions,
  through: :contact_alert_subscriptions
```

**New methods:**
```ruby
# Check if contact is subscribed to a specific alert
def subscribed_to?(alert_definition_code)
  alert_definitions.active.exists?(code: alert_definition_code)
end

# Get only active subscriptions
def active_alert_subscriptions
  contact_alert_subscriptions.
    joins(:alert_definition).
    where(active: true).
    merge(AlertDefinition.active)
end

# Subscribe to an alert by code
def subscribe_to!(alert_definition_code)
  definition = AlertDefinition.active.find_by!(code: alert_definition_code)
  contact_alert_subscriptions.find_or_create_by!(alert_definition: definition)
end

# Unsubscribe from an alert by code
def unsubscribe_from!(alert_definition_code)
  definition = AlertDefinition.find_by!(code: alert_definition_code)
  contact_alert_subscriptions.where(alert_definition: definition).destroy_all
end
```

### `GrdaWarehouse::Contact::User` (NEW)

**Location:** `app/models/grda_warehouse/contact/user.rb`

New contact type for user-level system alerts.

```ruby
module GrdaWarehouse::Contact
  class User < Base
    belongs_to :user,
      foreign_key: :entity_id

    validates :entity_type,
      inclusion: { in: ['User'] }
  end
end
```

### `GrdaWarehouse::AlertDefinition` (NEW)

**Location:** `app/models/grda_warehouse/alert_definition.rb`

```ruby
module GrdaWarehouse
  class AlertDefinition < GrdaWarehouseBase
    VALID_CATEGORIES = %w[
      system
      data_quality
      client_activity
      enrollment
      administrative
    ].freeze

    has_many :contact_alert_subscriptions
    has_many :contacts,
      through: :contact_alert_subscriptions,
      source: :contact

    validates :code,
      presence: true,
      uniqueness: true
    validates :name,
      presence: true
    validates :category,
      presence: true,
      inclusion: { in: VALID_CATEGORIES }

    scope :active, -> { where(active: true) }
    scope :by_category, ->(category) { where(category: category) }
    scope :system_alerts, -> { by_category('system') }

    def self.seed_initial_definitions
      # See "Seed Data" section below
    end
  end
end
```

### `GrdaWarehouse::ContactAlertSubscription` (NEW)

**Location:** `app/models/grda_warehouse/contact_alert_subscription.rb`

```ruby
module GrdaWarehouse
  class ContactAlertSubscription < GrdaWarehouseBase
    belongs_to :contact,
      class_name: 'GrdaWarehouse::Contact::Base'
    belongs_to :alert_definition

    validates :contact_id,
      uniqueness: { scope: :alert_definition_id }

    scope :active, -> do
      where(active: true).
        joins(:alert_definition).
        merge(AlertDefinition.active)
    end

    delegate :code, :name, :category,
      to: :alert_definition,
      prefix: :alert
  end
end
```

### `User` Model Updates

**Location:** `app/models/user.rb`

**New associations:**
```ruby
has_many :contacts,
  class_name: 'GrdaWarehouse::Contact::Base',
  foreign_key: :entity_id
has_one :system_contact,
  -> { where(type: 'GrdaWarehouse::Contact::User') },
  class_name: 'GrdaWarehouse::Contact::User',
  foreign_key: :entity_id
```

**New methods:**
```ruby
# Get or create the user's system contact for managing alert subscriptions
def system_contact!
  system_contact || contacts.create!(
    type: 'GrdaWarehouse::Contact::User',
    entity_id: id,
    entity_type: 'User',
    user_id: id
  )
end

# Aggregate all alert subscriptions across all contact types
def all_alert_subscriptions
  GrdaWarehouse::ContactAlertSubscription.
    joins(:contact).
    where(contacts: { user_id: id }).
    active
end

# Check if user is subscribed to a system alert
def subscribed_to_system_alert?(alert_code)
  system_contact&.subscribed_to?(alert_code) || false
end

# Subscribe to a system alert (creates system contact if needed)
def subscribe_to_system_alert!(alert_code)
  system_contact!.subscribe_to!(alert_code)
end
```

## Migration Strategy

### Migration 1: Create `alert_definitions` table

```ruby
class CreateAlertDefinitions < ActiveRecord::Migration[7.0]
  def change
    create_table :alert_definitions do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :category, null: false
      t.text :description
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    add_index :alert_definitions,
      :code,
      unique: true
    add_index :alert_definitions,
      :category
  end
end
```

### Migration 2: Create `contact_alert_subscriptions` table

```ruby
class CreateContactAlertSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :contact_alert_subscriptions do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :alert_definition, null: false, foreign_key: true
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    add_index(
      :contact_alert_subscriptions,
      [:contact_id, :alert_definition_id],
      unique: true,
      name: 'index_contact_alerts_on_contact_and_definition',
    )
  end
end
```

### Migration 3: Seed initial alert definitions

```ruby
class SeedInitialAlertDefinitions < ActiveRecord::Migration[7.0]
  def up
    GrdaWarehouse::AlertDefinition.seed_initial_definitions
  end

  def down
    # Alert definitions will be removed via dependent: :destroy on subscriptions
    GrdaWarehouse::AlertDefinition.destroy_all
  end
end
```

### Migration 4: Migrate existing user notification preferences

```ruby
class MigrateUserNotificationPreferences < ActiveRecord::Migration[7.0]
  def up
    # Map old columns to new alert codes
    mappings = {
      'notify_on_new_account' => 'new_account',
      'notify_on_vispdat_completed' => 'vispdat_completed',
      'notify_on_client_added' => 'client_added',
      'notify_on_anomaly_identified' => 'anomaly_identified',
      'receive_account_request_notifications' => 'account_request',
      'receive_file_upload_notifications' => 'file_upload'
    }

    User.find_each do |user|
      needs_system_contact = false
      subscriptions_to_create = []

      mappings.each do |old_column, alert_code|
        next unless user.respond_to?(old_column)
        next unless user.send(old_column)

        definition = GrdaWarehouse::AlertDefinition.find_by(code: alert_code)
        next unless definition

        needs_system_contact = true
        subscriptions_to_create << {
          alert_definition_id: definition.id,
          active: true
        }
      end

      if needs_system_contact && subscriptions_to_create.any?
        contact = user.system_contact!
        subscriptions_to_create.each do |attrs|
          contact.contact_alert_subscriptions.find_or_create_by!(attrs)
        end
      end
    end
  end

  def down
    # Optionally restore boolean flags from subscriptions
    # Likely not needed if we keep columns during transition
  end
end
```

### Migration 5: Add deprecation warnings to user notification columns (Future)

```ruby
class DeprecateUserNotificationColumns < ActiveRecord::Migration[7.0]
  def change
    # Add comments to columns indicating they're deprecated
    change_column_comment(
      :users,
      :notify_on_new_account,
      'DEPRECATED: Use alert_definitions subscription system',
    )
    change_column_comment(
      :users,
      :notify_on_vispdat_completed,
      'DEPRECATED: Use alert_definitions subscription system',
    )
    change_column_comment(
      :users,
      :notify_on_client_added,
      'DEPRECATED: Use alert_definitions subscription system',
    )
    change_column_comment(
      :users,
      :notify_on_anomaly_identified,
      'DEPRECATED: Use alert_definitions subscription system',
    )
    change_column_comment(
      :users,
      :receive_account_request_notifications,
      'DEPRECATED: Use alert_definitions subscription system',
    )
    change_column_comment(
      :users,
      :receive_file_upload_notifications,
      'DEPRECATED: Use alert_definitions subscription system',
    )
  end
end
```

### Migration 6: Remove deprecated notification columns (Far Future)

After confirming the new system works in production for several releases:

```ruby
class RemoveDeprecatedUserNotificationColumns < ActiveRecord::Migration[7.0]
  def change
    remove_column :users,
      :notify_on_new_account,
      :boolean
    remove_column :users,
      :notify_on_vispdat_completed,
      :boolean
    remove_column :users,
      :notify_on_client_added,
      :boolean
    remove_column :users,
      :notify_on_anomaly_identified,
      :boolean
    remove_column :users,
      :receive_account_request_notifications,
      :boolean
    remove_column :users,
      :receive_file_upload_notifications,
      :boolean
  end
end
```

## Seed Data - Initial Alert Definitions

### System Category (User-level)

| Code | Name | Description |
|------|------|-------------|
| `new_account` | New Account Creation | Notification when a new user account is created by an external system |
| `account_request` | Account Request | Notification when a user requests a new account |
| `file_upload` | File Upload | Notification when files are uploaded to the system |

### Client Activity Category (Project/Org-level)

| Code | Name | Description |
|------|------|-------------|
| `vispdat_completed` | VI-SPDAT Completed | Notification when a VI-SPDAT assessment is submitted |
| `client_added` | Client Added | Notification when a new client is added to authoritative data source |

### Data Quality Category (Project/Org-level)

| Code | Name | Description |
|------|------|-------------|
| `anomaly_identified` | Anomaly Identified | Notification when data anomalies are detected |
| `data_quality_report` | Data Quality Report Available | Notification when a data quality report is ready |

### Enrollment Category (Project-level)

| Code | Name | Description |
|------|------|-------------|
| `enrollment_milestone` | Enrollment Milestone | Notification when enrollment reaches a threshold |

## View/Form Updates

### User Edit Page - System Alert Subscriptions

**Location:** `app/views/admin/users/_form_fields.haml` (lines 52-64)

Replace existing notification checkboxes section with:

```haml
.col-sm-6
  .form--checkbox-groups
    %h3 System Notifications
    .well
      %p Which system-wide notifications should this user receive?
      = f.simple_fields_for :system_contact, @user.system_contact || @user.build_system_contact do |sc_form|
        = sc_form.input :alert_definition_ids,
          as: :check_boxes,
          collection: GrdaWarehouse::AlertDefinition.system_alerts.active.order(:name),
          label_method: :name,
          value_method: :id,
          checked: @user.system_contact&.alert_definition_ids || [],
          wrapper_html: { class: 'system-alerts' },
          label: false
```

### User Edit Page - Contact Relationships Summary

**Location:** `app/views/admin/users/edit.haml` (lines 11-13)

Implement the commented-out contact relationships section:

```haml
- unless @user.new_record?
  = render 'contact_relationships'
```

**New partial:** `app/views/admin/users/_contact_relationships.haml`

```haml
.contact-relationships
  %h3 Alert Contact Relationships
  .well
    %p
      This user receives alerts through the following contact associations.
      Click to edit subscriptions for each contact.

    %table.table.table-condensed
      %thead
        %tr
          %th Contact Type
          %th Entity
          %th Alert Subscriptions
          %th Actions
      %tbody
        - if @user.system_contact
          %tr
            %td System
            %td= @user.name
            %td
              = @user.system_contact.alert_definitions.active.pluck(:name).join(', ')
            %td
              %em Managed above

        - @user.contacts.where(type: 'GrdaWarehouse::Contact::Organization').includes(:organization, :alert_definitions).each do |contact|
          %tr
            %td Organization
            %td= contact.organization.name
            %td
              = contact.alert_definitions.active.pluck(:name).join(', ')
            %td
              = link_to 'Edit', edit_organization_contact_path(contact.organization, contact)

        - @user.contacts.where(type: 'GrdaWarehouse::Contact::Project').includes(:project, :alert_definitions).each do |contact|
          %tr
            %td Project
            %td= contact.project.name
            %td
              = contact.alert_definitions.active.pluck(:name).join(', ')
            %td
              = link_to 'Edit', edit_project_contact_path(contact.project, contact)
```

### Organization Contacts Form

**Location:** `app/views/organizations/contacts/_form.haml`

Add alert subscription section:

```haml
= f.error_notification

= f.association :user,
  collection: GrdaWarehouse::Contact::Organization.available_users(@entity, include_current: include_current),
  label_method: :name_with_email,
  value_method: :id,
  include_blank: true,
  as: :select_two,
  required: true,
  selected: f.object.user_id

.form-group
  %label Alert Subscriptions
  %p.help-block Select which alerts this contact should receive for this organization

  - GrdaWarehouse::AlertDefinition::VALID_CATEGORIES.each do |category|
    - next if category == 'system' # System alerts only on user form
    - alerts = GrdaWarehouse::AlertDefinition.by_category(category).active
    - next if alerts.empty?

    .alert-category
      %h5= category.titleize
      = f.association :alert_definitions,
        as: :check_boxes,
        collection: alerts.order(:name),
        label_method: :name,
        value_method: :id,
        wrapper_html: { class: "alert-category-#{category}" },
        label: false
```

### Project Contacts Form

**Location:** `app/views/projects/contacts/_form.haml`

Mirror organization form structure (same as above, but replace `Organization` with `Project`).

## Controller Updates

### `Admin::UsersController`

**Updates needed:**

1. Update strong parameters to accept nested system contact attributes:

```ruby
def user_params
  params.require(:user).permit(
    :first_name,
    :last_name,
    :email,
    # ... existing params ...
    system_contact_attributes: [
      :id,
      alert_definition_ids: [],
    ],
  )
end
```

2. Preload contacts with alert subscriptions:

```ruby
def edit
  @user = User.
    includes(
      system_contact: :alert_definitions,
      contacts: [:alert_definitions, :organization, :project],
    ).
    find(params[:id])
end
```

3. Add helper for migration (temporary):

```ruby
# Helper method to sync old boolean flags to new subscriptions
def sync_legacy_notifications(user)
  mappings = {
    'notify_on_new_account' => 'new_account',
    'notify_on_vispdat_completed' => 'vispdat_completed',
    'notify_on_client_added' => 'client_added',
    'notify_on_anomaly_identified' => 'anomaly_identified',
    'receive_account_request_notifications' => 'account_request',
    'receive_file_upload_notifications' => 'file_upload'
  }

  mappings.each do |old_column, alert_code|
    next unless user.send(old_column)
    user.subscribe_to_system_alert!(alert_code)
  end
end
```

### `OrganizationsContactsController` & `ProjectsContactsController`

**Updates needed:**

1. Update strong parameters:

```ruby
def contact_params
  params.require(:contact).permit(
    :user_id,
    alert_definition_ids: [],
  )
end
```

2. Handle subscription updates on save (standard Rails nested attributes handling)

## Code Migration Plan

### Phase 1: Deploy New System (Non-Breaking)

1. Deploy migrations 1-3 (tables, models, seed data)
2. Deploy model changes and new methods
3. No changes to existing notification code yet
4. System runs in parallel with old boolean flags

### Phase 2: Backfill Data

1. Run migration 4 to backfill existing user preferences
2. Verify data integrity
3. Test that new system returns same results as old flags

### Phase 3: Update Code References

Replace old patterns with new ones:

**Old:**
```ruby
User.where(notify_on_new_account: true).each do |user|
  # Send notification
end
```

**New:**
```ruby
alert_definition = GrdaWarehouse::AlertDefinition.find_by!(code: 'new_account')
contacts = GrdaWarehouse::Contact::User.
  joins(:contact_alert_subscriptions).
  where(
    contact_alert_subscriptions: {
      alert_definition_id: alert_definition.id,
      active: true,
    },
  ).
  includes(:user)

contacts.each do |contact|
  user = contact.user
  # Send notification
end
```

**Helper method for cleaner querying:**

```ruby
# In GrdaWarehouse::AlertDefinition
def subscribed_users
  GrdaWarehouse::Contact::User.
    joins(:contact_alert_subscriptions).
    where(
      contact_alert_subscriptions: {
        alert_definition_id: id,
        active: true,
      },
    ).
    includes(:user).
    map(&:user)
end

# Usage:
GrdaWarehouse::AlertDefinition.
  find_by!(code: 'new_account').
  subscribed_users.
  each do |user|
    # Send notification
  end
```

**Update User scopes in `app/models/concerns/user_concern.rb`:**

```ruby
# Old scopes (lines 98-108) - deprecate these
scope :receives_account_request_notifications, -> do
  where(receive_account_request_notifications: true)
end

# New scopes
scope :subscribed_to_alert, ->(alert_code) do
  joins(system_contact: { contact_alert_subscriptions: :alert_definition }).
    where(
      alert_definitions: {
        code: alert_code,
        active: true,
      },
    ).
    where(contact_alert_subscriptions: { active: true })
end

# Convenience scopes for specific alerts
scope :receives_account_request_notifications, -> { subscribed_to_alert('account_request') }
scope :receives_new_account_notifications, -> { subscribed_to_alert('new_account') }
# etc.
```

### Phase 4: Deprecate Old Columns (Future Release)

1. Deploy migration 5 to add deprecation warnings
2. Add ActiveSupport deprecation warnings when old columns are accessed
3. Monitor logs for usage

### Phase 5: Remove Old Columns (Far Future Release)

1. After several releases with no usage of old columns
2. Deploy migration 6 to drop deprecated columns
3. Remove any remaining compatibility code

## Key Design Decisions

### 1. Three Contact Scopes via Polymorphic Association

- **User-level** (`entity_type: 'User'`): System-wide alerts managed on user form
- **Organization-level**: Organization-specific alerts managed on organization contacts
- **Project-level**: Project-specific alerts managed on project contacts

This leverages existing polymorphic structure without adding new tables.

### 2. Category-Based Organization

Categories group related alerts in UI and make the system scalable as alert types grow. Categories are validated but extensible.

### 3. Alert Definitions vs Alert Types

Using `alert_definitions` avoids Rails reserved word `type` (used for STI) and clearly indicates these are configuration templates, not instances.

### 4. Subscription-Based vs Boolean Flags

Subscriptions provide:
- Extensibility (add alerts without schema changes)
- Granularity (different alerts per contact role)
- Audit trail (timestamps on subscriptions)
- Flexibility (active flag allows temporary disable)

### 5. Backward Compatibility During Transition

- Dual-write during migration
- Maintain old columns until proven stable
- Provide compatibility scopes
- Safe rollback path

### 6. User Experience

- System alerts remain on user edit form (familiar location)
- Organization/project alerts on respective contact forms (logical grouping)
- Read-only summary on user page shows complete alert picture

## Future Enhancements

### Delivery Preferences

Add fields to `contact_alert_subscriptions`:
- `delivery_method` (email, SMS, in-app)
- `frequency` (immediate, daily digest, weekly digest)
- `last_sent_at` (for digest batching)

### Alert History

Track when alerts are sent:

```ruby
create_table :alert_deliveries do |t|
  t.references :contact_alert_subscription, null: false
  t.references :alert_definition, null: false
  t.string :delivery_method
  t.string :recipient_email
  t.datetime :sent_at
  t.string :status # pending, sent, failed, bounced
  t.text :error_message
  t.json :metadata # Alert-specific data
  t.timestamps
end
```

### Unsubscribe Tokens

Generate secure tokens for email unsubscribe links:

```ruby
add_column :contact_alert_subscriptions, :unsubscribe_token, :string
add_index :contact_alert_subscriptions, :unsubscribe_token, unique: true
```

### Admin Interface

Create admin UI for managing alert definitions:
- Enable/disable alerts
- Edit descriptions
- Add new alert types
- View subscription statistics

### Alert Templates

Store customizable message templates per alert:

```ruby
create_table :alert_templates do |t|
  t.references :alert_definition, null: false
  t.string :delivery_method # email, sms, in_app
  t.string :subject
  t.text :body_template # ERB or Liquid template
  t.timestamps
end
```

## Testing Considerations

### Model Tests

- Validate uniqueness constraints
- Test subscription helper methods
- Test scopes and associations
- Test category validations

### Controller Tests

- Test nested attributes handling
- Test strong parameters
- Test subscription creation/deletion

### Integration Tests

- Test user workflow: create user → add system alert subscription
- Test organization workflow: add contact → subscribe to alerts
- Test project workflow: add contact → subscribe to alerts
- Test migration from old boolean flags

### System Tests

- Test UI for managing subscriptions
- Test checkbox persistence
- Test category grouping display

## Rollout Strategy

1. **Release N:** Deploy tables, models, seed data (non-breaking)
2. **Release N+1:** Backfill existing preferences, deploy new UI
3. **Release N+2:** Update code to use new system, maintain old columns
4. **Release N+3:** Add deprecation warnings to old columns
5. **Release N+4+:** Monitor usage, prepare for column removal
6. **Release N+6+:** Remove old columns after extended stability period

## References

- Contact base model: `app/models/grda_warehouse/contact/base.rb`
- User model: `app/models/user.rb`
- User concern: `app/models/concerns/user_concern.rb`
- Current user form: `app/views/admin/users/_form_fields.haml`
- Organization contacts: `app/views/organizations/contacts/_form.haml`
- Project contacts: `app/views/projects/contacts/_form.haml`
