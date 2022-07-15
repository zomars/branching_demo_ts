# Neon branching demo

This app is a simple collective blog model based on the `rest-nextjs-api-routes` example from the Prisma project. It is deployed on https://branching-demo-ts.vercel.app/ with the Postgres database running at http://neon.tech/.

The primary purpose of this repo is to demonstrate CI/CD setup which can catch SQL migration problems on production data before actually applying migrations on production.

This app uses GitHub action to run its tests. Vercel deploy happens only if tests succeed, that is why we trigger deploy from CI instead of using the Vercel bot (the bot will deploy PR regardless of CI status, see https://github.com/vercel/vercel/discussions/5776).

## Migration failure example


<a href="http://www.youtube.com/watch?feature=player_embedded&v=xxiR8nYbCgM" target="_blank">
 <img src="http://img.youtube.com/vi/xxiR8nYbCgM/mqdefault.jpg" alt="Watch the video" width="240" height="180" border="10" />
</a>


1. Clone repo. To make it work locally run `npm install` and set following in the `.env` file:
  ```
  DATABASE_URL=postgres://<your_local_username>@localhost/branching_demo_ts
  NEXT_PUBLIC_VERCEL_URL=localhost:3000
  NEXT_PUBLIC_URL_PREFIX=http://
  ```
1. Ensure that [](prisma/schema.prisma) has `User.name` field typed as `String?`. If no, then commit a change to make it `String?`
2. Go to the [](https://branching-demo-ts.vercel.app/) and create a post with an empty name. That will end up in `User` table as a NULL value for the user name
3. Create a PR that changes the schema to force `not null` on user names (`String?` -> `String`). It will fail in the CI since migration will not pass:
  ```
  > git checkout -b not_null_names
  > <edit prisma/schema.prisma>
  > npx prisma migrate dev --name not_null_names
  > git add prisma/migrations
  > git commit -am 'Force non-null usernames'
  > git push --set-upstream origin not_null_names
  ```
  After that go to the github repo webpage and click on a green box that suggest to create a PR. CI check will automatically start on the PR. It will fail since NULL names among users. You can go to the actions tab and look up otput for `ERROR: column "name" of relation "User" contains null values` error.
4. Go to the [](https://console.stage.neon.tech) and set some names to users with null names, e.g. `update "User" set name='Stas' where email='stas3@stas.to'`
5. Now re-run CI on the pull request. Go to `Actions`, select last run, and click `re-run all jobs` button in the top right corner. CI should pass now.

## How to set your test stand

Since Neon still has no shared projects, one will need to reconfigure this setup to run everything on their own account.

1. You will need GitHub, Vercel, and Neon accounts
1. Clone this repo to your GitHub account
1. Create a database in Neon
1. Attach the GitHub repo to your Vercel account. Go to the project setting in Vercel, the to `Environment Variables` and set the following env variables:
    * `NEXT_PUBLIC_URL_PREFIX` to `https://`
    * `DATABASE_URL` to the connection string to the Neon database. Save the password as you'll need it later.
    * `NEON_API_TOKEN` -- neon api token, get one at https://console.neon.tech/app/settings/api-keys
    * `NEON_PG_CREDENTIALS` -- user:pass for your cluster, e.g. `stas:mypass`
    * `NEON_PG_CLUSTER` -- neon cluster name, e.g. `lucky-field-758416`
    * `VERCEL_TOKEN` -- vercel api token, get one at https://vercel.com/account/tokens
1. Then you need to set `./scripts/vercel.sh` at your project's [Ignored Build Step](https://vercel.com/docs/concepts/projects/overview#ignored-build-step).  
1. All set, now you can deploy to Vercel  by pushing to a branch on GitHub.
