# Rails 6 Update Notes

Since my approach to this is to update everything then slowly fix the faulty parts one by one until everything is in shape, naturally, I run into a lot of bugs, problems and issues. This will be a documentation of all the bugs I (and others) encoutered while I (and others) perform the Rails 6 update to the HMIS-Warehouse Rails app.

The aim of this document is to make clear some decisions that are not self-documented by the code pertaining to updating to Rails 6. Hopefully it will be of use in the future for people working on this project, and hopefully for others attempting to, or working on a Rails 6 project too.

As of writing, I am attempting to update the application to work with Rails 6.1.1, so some of the issues here might have already been fixed, though it's not like I would know for sure.

*Table of Contents*
- [Rails 6 Update Notes](#rails-6-update-notes)
  - [Gems update and Rails 6.1.1 compatibility](#gems-update-and-rails-611-compatibility)
  - [database.yml ERB and Rails 6.1.1 Multiple database support](#databaseyml-erb-and-rails-611-multiple-database-support)
  - [Non-primary database and missing Rails 6.1 pending migration error](#non-primary-database-and-missing-rails-61-pending-migration-error)
  - [Zeitwerk autoloading and camelized filenames](#zeitwerk-autoloading-and-camelized-filenames)
  - [Rails 6.1 and update_attributes (and future deprecated methods)](#rails-61-and-update_attributes-and-future-deprecated-methods)
  - [Arel::Nodes::Values removed in 6.1.1](#arelnodesvalues-removed-in-611)

## Gems update and Rails 6.1.1 compatibility

95% of the gems in our Gemfile already have 6.1.1 compatibility in its latest version, but of course I would have prefered if that number was 100% so I wouldn't have to do actual research.

As of writing, these are the Gems that didn't yet have official 6.1.1 support, as well as which fork I used to bring the gem up to date.

- composite_ primary_keys
  - Currently using codeodor's version [here](https://github.com/codeodor/composite_primary_keys) on branch `ar6.1`
  - PR on official repo is [here](https://github.com/composite-primary-keys/composite_primary_keys/pull/531)
- activerecord-sqlserver-adapter
  - Currently using lk001's version [here](https://github.com/lk0001/activerecord-sqlserver-adapter) on branch `master`.
  - Issue on official repo is [here](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/issues/849)
- active_record_extended
  - Officially already supporting 6.1, but currently using the unreleased version on the Master branch as it fixed a small bug.
- devise-two-factor
  - Currently using jason-hobbs's version [here](https://github.com/jason-hobbs/devise-two-factor) on branch `master`
  - PR on official repo is [here](https://github.com/tinfoil/devise-two-factor/pull/185)

## database.yml ERB and Rails 6.1.1 Multiple database support

From how I could understand it:

1) Rails parse database.yml to detect whether the app uses multiple database to generate the corresponding tasks at initialization.

2) However, since this is done before `load_config` is called, no Rails env configuration is loaded yet.

3) Since ERB could contain Rails env configuration and thus could break when it's loaded initially, all ERB is stripped initially.

Since our old `database.yml` use ERB at the top level, when this is stripped out, Rails wouldn't understand whether we want multi-db support or not, and would give the "Rails couldn't infer whether you are using multiple databases" warning. [Source](https://github.com/rails/rails/issues/38924#issuecomment-612881746).

```
<%= ENV['RAILS_ENV'] %>:
  <<: *default
...
```

All of this means that I had to unroll the `RAILS_ENV` variable and make it clearer for Rails:

```
development:
  primary:
    database: <%= ENV['DATABASE_APP_DB'] %>
    <<: *default_app_db
  <<: *other_db
  
staging:
  primary:
    database: <%= ENV['DATABASE_APP_DB'] %>
    <<: *default_app_db
    <<: *ssl
  <<: *other_db
...
```

A current feature that is being worked on could make this be resolved much more elegantly, though sadly it's not out in 6.1.1 yet. The PR for that is [here](https://github.com/rails/rails/pull/38721). In essence, it gives the option of defining database configurations using a Ruby DSL, instead of using a YML file, which "makes it easier to build complex configurations programmatically.".

## Non-primary database and missing Rails 6.1 pending migration error

The issue for that is still open as of writing [here](https://github.com/rails/rails/issues/37524).

In essence, a PendingMigrationError will still be raised for the primary database, but this is not the case for non-primary databases. For now, our workaround is to manually call `needs_migration?` on a new MigrationContext.

```
def self.needs_migration?
    ActiveRecord::MigrationContext.new(<db migration path>, <db schema migration>).needs_migration?
end
```

## Zeitwerk autoloading and camelized filenames

Zeitwerk is a new code reloader/autoloader that is replacing the classic reloader in Rails 6, the latter of which is being deprecated.

While running some tasks, I ran into a lot of `NameError: uninitialized constant` and `Zeitwerk::NameError: expected file to define constant, but didn't`. Most of this was due to the fact that, according to the official update guide [here](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#autoloading):

```
In classic mode, given a missing constant Rails underscores its name and performs a file lookup. On the other hand, zeitwerk mode checks first the file system, and camelizes file names to know the constant those files are expected to define.
```

In other words, Zeitwerk will camelize filenames and expect the file to have the constant it is looking for. Therefore, if a file is called `hud` but the module defined is `HUD` in all caps, Zeitwerk would not pick this up, since `"hud".camelize` gives `Hud` instead. This was also a problem for files in our project with `coc` in the name, like `project_coc`, since `"project_coc".camelize` gives `ProjectCoC`, while the module defined is `ProjectCoc`, with the last c having different cases.

The fix for this of course is to simply rename the files to match the module/constant name, though if this doesn't look right aesthetically then an alternative would be to rename all occurences of the module/constant name in the project to match the camelized filename instead.

It's also good to note that a `bin/rails zeitwerk:check` task is provided, that would help with the process of searching for violating files.

## Rails 6.1 and update_attributes (and future deprecated methods)

Since I updated straight to 6.1 instead of going through 6, I didn't catch this until I read about it in [this post](https://blog.saeloun.com/2019/04/15/rails-6-deprecates-update-attributes.html). `update_attributes` as well as `update_attributes!` are deprecated in Rails 6, and are removed in 6.1, meaning it would have shown a warning regarding this in 6.

What this means is that there might be other methods that are deprecated in Rails 6 that I do not know of. This section will be for those instances in the future.

(It should be noted that this was not mentioned in the official Rails 6 update guide)

## Arel::Nodes::Values removed in 6.1.1

The commit for that is [here](https://github.com/rails/rails/commit/187870db2fcc58aa0da8bb3f26711664fd5ed611)