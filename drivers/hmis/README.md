# HMIS Driver

This driver contains all the backend logic for supporting the [HMIS Frontend](https://github.com/greenriver/hmis-frontend).

## Local Development

To enable the HMIS driver locally:
```bash
ENABLE_HMIS_API=true
HMIS_HOSTNAME=hmis.dev.test
```

### Multi-HMIS Local Development

How to run multiple HMIS frontends (e.g. `hmis.dev.test` and `hmis-2.dev.test`) against a single Warehouse locally.

#### Prerequisites

- Warehouse and frontend set up per [setup.md](setup.md) and frontend README.
- Each HMIS hostname resolves to localhost (e.g. dnsmasq `*.dev.test` → `127.0.0.1`). If you followed [prerequisites.md](prerequisites.md) or the automated install in setup.md, this is set up already.

#### Setup

**1. Configure second data source**. For example, in rails console:
```ruby
ds = GrdaWarehouse::DataSource.hmis.last.dup
ds.name = 'HMIS 2'
ds.short_name = 'HMIS 2'
ds.hmis = 'hmis-2.dev.test'
ds.save!
```

**2. Set up warehouse env**. For example, in `.env.development.local`:
```bash
ENABLE_HMIS_API=true
HMIS_HOSTNAME=hmis.dev.test,hmis-2.dev.test # Comma-separated list of hostnames
```

**3. Run two dev servers:**
```bash
# Terminal 1
yarn dev

# Terminal 2
HMIS_HOST=hmis-2.dev.test yarn dev
```

Use the URLs shown by the vite server (e.g. `https://hmis.dev.test:5173` and `https://hmis-2.dev.test:5174`). Each is scoped to its data source via the custom header `X-Hmis-Dev-Host`.

## Testing

End-to-end tests are located in [drivers/hmis/spec/system/hmis](spec/system/hmis). See [E2E_TESTING_README.md](E2E_TESTING_README.md) for detailed instructions on running and developing E2E tests.

## New Deployment Checklist

Some things need to be done manually for a new deployment:

* Create the HMIS Data Source
* Create an HMIS Administrator role
* Configure permissions in the warehouse
* Set up File Tags in the warehouse
* Create any UnitTypes
* Create any CustomServiceTypes and categories
* Create any CustomDataElementDefinitions
* Set up any RemoteCredentials
* Enable any InboundApiConfigurations
* Create a GrdaWarehouse::Theme
