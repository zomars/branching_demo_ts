if [ "$VERCEL_GIT_COMMIT_SHA" == "" ]; then
  echo "Error: VERCEL_GIT_COMMIT_SHA is empty"
  exit 0
fi

if [ "$VERCEL_TOKEN" == "" ]; then
  echo "Error: $VERCEL_TOKEN is empty"
  exit 0
fi

# github access token is necessary
# add it to Environment Variables on Vercel
if [ "$GITHUB_ACCESS_TOKEN" == "" ]; then
  echo "Error: GITHUB_ACCESS_TOKEN is empty"
  exit 0
fi

# We only branch if it's not main
if [ "$VERCEL_GIT_COMMIT_REF" == "main" ]; then
  exit 1
fi

# create branch
BRANCH_NAME=$(curl -o - -X POST -H "Authorization: Bearer $API_TOKEN" https://console.neon.tech/api/v1/projects/$PG_CLUSTER/branches | jq -r '.id')

# switch to branch
BRANCH_URL=$(postgres://$PG_CREDENTIALS@$BRANCH_NAME.cloud.neon.tech/main)

# We update DATABASE_URL using Vercel API
curl -o - -X POST "https://api.vercel.com/v1/projects/$VERCEL_PROJECT_ID/env?teamId=$VERCEL_ORG_ID" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $VERCEL_TOKEN" \
  --data-raw '{
    "target": "preview",
    "gitBranch": "'$VERCEL_GIT_COMMIT_REF'",
    "type": "encrypted",
    "key": "DATABASE_URL",
    "value": "'$BRANCH_URL'"
}'
