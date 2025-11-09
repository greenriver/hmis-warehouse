# Zitadel IDP

The warehouse has run since 2017 using the [devise](https://github.com/heartcombo/devise) gem for authentication.  We are now switching to an Oauth2 authentication system that includes [Oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/) in front of [Dex](https://dexidp.io) which proxies pretty much any IDP. For installations where the community does not have an existing IDP, we use a stand-alone installation of [Zitadel](https://zitadel.com) to provide user management.

This document does not cover installation of Zitadel but attempts to explain enough about the configuration so that the migration of user data can take place.

# Architecture Overview

This setup uses **a single Dex connector** to Zitadel with **shared authentication cookies** between Warehouse and HMIS:

- Users log in once and gain access to both applications (SSO behavior)
- Access control is managed via **Zitadel project grants** - you can restrict which users can access which projects
- Both applications share the same authentication session
- You can optionally create separate Zitadel projects for Warehouse and HMIS to manage users independently, but they use the same Dex connector

# Initial Configuration

## 1. Configure Zitadel Organization and SMTP

1. Login to Zitadel as an administrator
2. Click **Default Settings** (or your organization name)
3. Click **SMTP Provider**
4. Click **Generic SMTP**
5. Give it a name (mailhog)
6. Host and Port: `mailhog:1025`, user: `local`, password: `local`, click **Continue**
7. Sender Email Address: `noreply@zitadel.dev.test` Sender Name: `Zitadel Dev`, click **Continue**
8. Click **Test**, you should receive a test message in Mailhog.  Click **Create**, Click **Activate**

## 2. Create Dex Application in Zitadel

1. Click **Projects**
2. Create a project called **Identity Provider** (or use an existing project)
3. Click **+** to add an Application
4. Name the application **Dex Connector** and choose type **WEB**, click **Continue**
5. Choose **CODE**, click **Continue**
6. Turn on **Development Mode** to allow using `http` in development (not needed in production)
7. Add a **Redirect URI**: `https://dex.dev.test/dex/callback`
8. Add **Post Logout URIs** (IMPORTANT for logout redirect):
   - `https://hmis-warehouse.dev.test/oauth2/sign_out`
   - `https://hmis.dev.test/oauth2/sign_out`
9. Click **Continue**, click **Create**
10. **IMPORTANT**: After creating the application, click on it and go to **Token Settings**:
    - Change **Auth Token Type** to **JWT** (if not already)
    - Under **Additional Settings**, enable **Assert Roles on Authentication**
    - **This allows all organization users to authenticate without needing project-specific grants**
11. **Copy the ClientId and ClientSecret** - add to `.env.local`:
    ```bash
    ZITADEL_IDP_CLIENT_ID=<client-id>
    ZITADEL_IDP_CLIENT_SECRET=<client-secret>
    ```
12. Copy the **Organization ID** (from organization settings) to `.env.local`:
    ```bash
    ZITADEL_ORG_ID=<org-id>
    ```

## 3. (Optional) Create Separate Projects for Access Control

If you want to manage Warehouse and HMIS users separately:

1. Click **Projects**
2. Create a project called **Warehouse** and note its Project ID
3. Create a project called **HMIS** and note its Project ID
4. Add these to `.env.local`:
    ```bash
    ZITADEL_WAREHOUSE_PROJECT_ID=<warehouse-project-id>
    ZITADEL_HMIS_PROJECT_ID=<hmis-project-id>
    ```
5. Use Zitadel's **Project Grants** feature to assign users to specific projects

**Note**: Even with separate projects, users log in once and can access both applications by default. Use project grants to restrict access if needed.

## 4. Create a Service User for Managing Users

The service user is needed for the rake tasks that import/export users.

1. Go to your Zitadel **Organization** (not a specific project)
2. Click on **Users**, then **Service Users**, then **New**
3. Set the User Name and Name to **rails-app**, leave Access Token Type as **Bearer**, click **Create**
4. Click **Personal Access Tokens**, Click **New**, leave the expiration date empty
5. **Copy the token** and add to `.env.local`:
   ```bash
   ZITADEL_API_URL=http://zitadel.dev.test:8080
   ZITADEL_SERVICE_USER_TOKEN=<your-service-user-token>
   ```
6. Click **Organization**, then click the `+` next to the Actions menu
7. Choose the `rails-app` user and check **Org User Manager**, click **Add**
8. Click **Default Settings**
9. Click the `+` next to the ZA and Robot icons
10. Choose the **rails-app** user, grant **Iam Owner** and **Iam User Manager**, click **Add**

## 5. Complete Environment Configuration

Your `.env.local` should now have all the necessary Zitadel configuration:

```bash
# Dex Configuration
DEX_ISSUER=https://dex.dev.test/dex

# Zitadel API Configuration
ZITADEL_API_URL=http://zitadel.dev.test:8080
ZITADEL_SERVICE_USER_TOKEN=<service-user-token>

# Zitadel Organization and Dex Application
ZITADEL_ORG_ID=<org-id>
ZITADEL_IDP_CLIENT_ID=<dex-client-id>
ZITADEL_IDP_CLIENT_SECRET=<dex-client-secret>

# Optional: Separate projects for access control
ZITADEL_WAREHOUSE_PROJECT_ID=<warehouse-project-id>  # For rake tasks
ZITADEL_HMIS_PROJECT_ID=<hmis-project-id>            # For rake tasks
```

## 6. Restart Services

```bash
docker compose restart dex oauth2-proxy oauth2-proxy-hmis
```

# User Migration

## Test Connection

```bash
rails zitadel:test_connection
```

## Export and Import Warehouse Users

1. Export a sample of 2 Warehouse users for testing:
   ```bash
   rails zitadel:export_users[warehouse,2]
   ```

2. Verify `tmp/zitadel_warehouse_users_export.json` looks correct

3. Import users to Warehouse project:
   ```bash
   rails zitadel:import_users[warehouse,tmp/zitadel_warehouse_users_export.json]
   ```

4. Export all Warehouse users:
   ```bash
   rails zitadel:export_users[warehouse]
   ```

5. Import all users:
   ```bash
   rails zitadel:import_users[warehouse]
   ```

## Export and Import HMIS Users

1. Export HMIS users:
   ```bash
   rails zitadel:export_users[hmis,2]
   ```

2. Verify `tmp/zitadel_hmis_users_export.json` looks correct

3. Import users to HMIS project:
   ```bash
   rails zitadel:import_users[hmis,tmp/zitadel_hmis_users_export.json]
   ```

## Import Single User (for testing)

```bash
# Import to Warehouse project
rails zitadel:import_single_user[warehouse,user@example.com]

# Import to HMIS project
rails zitadel:import_single_user[hmis,user@example.com]
```

# Access Control

Users can be added to one or both projects:

- **Warehouse only**: User added to Warehouse project → can access Warehouse only
- **HMIS only**: User added to HMIS project → can access HMIS only
- **Both applications**: User added to both projects → can access both with SSO

To add an existing user to a project:
1. In Zitadel, navigate to the project (Warehouse or HMIS)
2. Click **Authorizations**
3. Click **+** to add a user
4. Search for and select the user
5. Grant appropriate role (or leave default)
