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
11. Copy the **ClientId** and **ClientSecret** values into your environment in `ZITADEL_IDP_CLIENT_ID` and `ZITADEL_IDP_CLIENT_SECRET`.  Is is most easily done by adding them to `.envrc`
