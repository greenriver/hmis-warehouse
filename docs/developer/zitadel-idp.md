# Zitadel IDP

The warehouse has run since 2017 using the [devise](https://github.com/heartcombo/devise) gem for authentication.  We are now switching to an Oauth2 authentication system that includes [Oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/) in front of [Dex](https://dexidp.io) which proxies pretty much any IDP. For installations where the community does not have an existing IDP, we use a stand-alone installation of [Zitadel](https://zitadel.com) to provide user management.

This document does not cover installation of Zitadel but attempts to explain enough about the configuration so that the migration of user data can take place.

# Initial Configuration

1. Login to Zitadel as an administrator
2. Click **Projects**
3. Create a project called **Open Path**
4. Click **+** to add an Application
5. Name the application **Warehouse** and choose type **WEB**, click **Continue**
6. Choose **CODE**, click **Continue**
7. Turn on **Development Mode** to allow using `http` in development, you do not need or want to do this in a hosted environment.
8. Add a **Redirect URI** that matches your configuration for Dex `http://dex.dev.test:4443/dex/callback`
9. Add a **Post Logout URI**, generally this would be the homepage `https://hmis-warehouse.dev.test`
10. Click **Continue**, click **Create**
11. Copy the **ClientId** and **ClientSecret** values into your environment in `ZITADEL_IDP_CLIENT_ID` and `ZITADEL_IDP_CLIENT_SECRET`.  Is is most easily done by adding them to `.env.local`
12. Click **Default Settings**
13. Click **SMTP Provider**
14. Click **Generic SMTP**
15. Give it a name (mailhog)
16. Host and Port: `mailhog:1025`, user: `local`, password: `local`, click **Continue**
17. Sender Email Address: `noreply@zitadel.dev.test` Sender Name: `Zitadel Dev`, click **Continue**
18. Click **Test**, you should receive a test message in Mailhog.  Click **Create**, Click **Activeate**

## Create a Service User for Migrating Warehouse Users
1. Go to the **Open Path** project in Zitadel
2. Click on **Users**, then **Service Users**, then **New**
3. Set the User Name and Name to **rails-app**, leave Access Token Type as **Bearer**, click **Create**
4. Click **Personal Access Tokens**, Click **New**, leave the expiration date empty
5. In `.env.local` set `ZITADEL_SERVICE_USER_TOKEN`, `ZITADEL_API_URL`,  `ZITADEL_ORG_ID`, and `ZITADEL_PROJECT_ID` appropriate values.
6. Click **Organization**, then click the `+` next to the Actions menu.
7. Choose the `rails-app` user and check **Org User Manager**, click **Add**
8. Click **Default Settings**
9. Click the `+` next to the ZA and Robot icons
10. Choose the **rails-app** user, grant **Iam Owner** and **Iam User Manager**, click **Add**

## Export/Import Process
1. Run `rails zitadel:test_connection` to confirm the connection is setup correctly
2. Run `rails zitadel:export_users[2]` to export a sample of 2 users
3. Verify `tmp/zitadel_users_export.json` to confirm it looks sane
4. Run `rails zitadel:import_users[tmp/zitadel_users_export.json]` to import users into Zitadel
