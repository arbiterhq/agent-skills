# Render REST API

Base URL: `https://api.render.com/v1`. Auth: `Authorization: Bearer $RENDER_API_KEY`
(create a key in the dashboard under Account Settings, API Keys). Full, current
reference: https://api-docs.render.com. Endpoints below are the commonly used
ones; verify shapes against the live docs since the API evolves.

All examples use the `render-api` helper, which adds auth, the base URL, and
pretty-prints with `jq`:

```bash
render-api GET /services
```

## Services

```bash
render-api GET /services                      # list (paginated, see below)
render-api GET "/services?type=web_service&limit=50"
render-api GET /services/srv-xxxx             # one service
render-api POST /services -d @service.json    # create
render-api PATCH /services/srv-xxxx -d '{"autoDeploy":"no"}'
render-api DELETE /services/srv-xxxx
```

Lifecycle:

```bash
render-api POST /services/srv-xxxx/suspend
render-api POST /services/srv-xxxx/resume
render-api POST /services/srv-xxxx/restart
render-api POST /services/srv-xxxx/scale -d '{"numInstances":3}'
```

## Deploys

```bash
render-api GET  /services/srv-xxxx/deploys            # history
render-api GET  /services/srv-xxxx/deploys/dep-yyyy   # one deploy
render-api POST /services/srv-xxxx/deploys            # trigger a deploy
render-api POST /services/srv-xxxx/deploys -d '{"clearCache":"clear"}'
```

## Environment variables

```bash
render-api GET /services/srv-xxxx/env-vars
render-api PUT /services/srv-xxxx/env-vars -d @env.json   # replaces the full set
```

`env.json` is an array: `[{"key":"NODE_ENV","value":"production"}, ...]`.

## Jobs (one-off commands)

Run a one-off command in the service environment (a managed equivalent of an
SSH command, useful from CI):

```bash
render-api POST /services/srv-xxxx/jobs -d '{"startCommand":"npm run migrate"}'
render-api GET  /services/srv-xxxx/jobs
render-api GET  /services/srv-xxxx/jobs/job-zzzz
```

## Events and logs

```bash
render-api GET /services/srv-xxxx/events
# Logs are owner-scoped and filtered by query params:
render-api GET "/logs?ownerId=tea-xxxx&resource=srv-xxxx&limit=100"
```

Log query parameters and retention vary by plan; check the live docs for the
exact `resource`, `type`, and time-range parameters.

## Datastores

```bash
render-api GET /postgres                       # list managed Postgres
render-api GET /postgres/dpg-xxxx
render-api GET /postgres/dpg-xxxx/connection-info
```

## Owners

```bash
render-api GET /owners        # accounts/teams the key can act on; gives ownerId (tea-... or usr-...)
```

The `ownerId` is needed for some list filters and for log queries.

## Pagination

List endpoints are cursor-paginated. Responses are arrays whose items each carry
a `cursor`. Pass the last item's cursor as `?cursor=...` with `?limit=N` (max
100) to get the next page:

```bash
render-api GET "/services?limit=100"
render-api GET "/services?limit=100&cursor=<cursor-from-last-item>"
```

When a page returns fewer than `limit` items, you have reached the end.

## Error handling

`render-api` uses `curl --fail-with-body`, so HTTP errors still print Render's
JSON error body and the helper exits non-zero. A `401` means the key is missing,
wrong, or lacks access to the resource's owner; a `404` usually means a typo in
the id or the resource belongs to a different owner than the key.
