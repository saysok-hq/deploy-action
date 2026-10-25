# saysOK deploy

A GitHub Action that tells saysOK about a deploy, so it shows as a marker on your monitors' charts and in incidents.

```yaml
- uses: saysok-hq/deploy-action@v1
  if: always()
  with:
    url: ${{ secrets.SAYSOK_DEPLOY_URL }}
    token: ${{ secrets.SAYSOK_DEPLOY_TOKEN }}
    status: ${{ job.status == 'success' && 'success' || 'failed' }}
```

Put it at the end of your deploy job. `if: always()` runs it after a failed deploy too, and `status` reports how the job went.

## Get the URL and token

In saysOK, open Integrations, then Deploy API, then Add a source. Copy the URL and the token into two repository secrets (`SAYSOK_DEPLOY_URL` and `SAYSOK_DEPLOY_TOKEN`).

## Inputs

| Input | Required | Default | Meaning |
|---|---|---|---|
| `url` | yes | | The Deploy API URL. |
| `token` | yes | | The Deploy API token. |
| `environment` | no | `production` | Where the deploy went. |
| `status` | no | `success` | `success` or `failed`. GitHub's `failure` and `cancelled` count as `failed`, so `${{ job.status }}` works as it is. |
| `title` | no | head commit message, else workflow name | The first line is kept. |
| `id` | no | run id, attempt, job and job index | The deploy's own id. A second post with the same id updates that deploy. |
| `fail-on-error` | no | `false` | Fail the step if the deploy is not recorded. |

The commit SHA, branch or tag, actor and a link to the run are sent from GitHub's context, with an id made of the run id, the attempt, the job and its index in a matrix (`run_id-run_attempt-job-jobindex`). So each job's deploy is its own (a staging and a production job, or the jobs of a matrix, are separate deploys), and a re-run is a new attempt, so it records a new deploy.

## Failing

By default a problem reaching saysOK only prints a warning, so a monitoring hiccup never breaks your deploy. Set `fail-on-error: "true"` to turn it into an error.

## Requirements

`curl` and `jq`, both present on GitHub-hosted runners.
