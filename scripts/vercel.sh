# We don't have jq installed on the CI, so we use this script to get it temporarily.
curl -sS https://webinstall.dev/jq | bash &>/dev/null
export PATH=/vercel/.local/bin/:$PATH

if [ "$VERCEL_GIT_COMMIT_SHA" == "" ]; then
  echo "Error: VERCEL_GIT_COMMIT_SHA is empty"
  exit 0
fi

if [ "$VERCEL_TOKEN" == "" ]; then
  echo "Error: $VERCEL_TOKEN is empty"
  exit 0
fi

if [ "$VERCEL_PROJECT_ID" == "" ]; then
  echo "Error: VERCEL_PROJECT_ID is empty"
  exit 0
fi

if [ "$VERCEL_ORG_ID" == "" ]; then
  echo "Error: VERCEL_ORG_ID is empty"
  exit 0
fi

if [ "$NEON_PG_CREDENTIALS" == "" ]; then
  echo "Error: NEON_PG_CREDENTIALS is empty"
  exit 0
fi

if [ "$NEON_PG_CLUSTER" == "" ]; then
  echo "Error: NEON_PG_CLUSTER is empty"
  exit 0
fi

if [ "$NEON_API_TOKEN" == "" ]; then
  echo "Error: API_TOKEN is empty"
  exit 0
fi

# We only branch if it's not main
if [ "$VERCEL_GIT_COMMIT_REF" == "main" ]; then
  exit 1
fi

# create branch
BRANCH_NAME=$(curl -sS -o - -X POST -H "Authorization: Bearer $NEON_API_TOKEN" https://console.neon.tech/api/v1/projects/$NEON_PG_CLUSTER/branches 2>/dev/null | jq -r '.id')

echo "Branch name: $BRANCH_NAME"

if [ "$BRANCH_NAME" == "" ]; then
  exit 0
fi

# switch to branch
BRANCH_URL=$(echo "postgres://$NEON_PG_CREDENTIALS@$BRANCH_NAME.cloud.neon.tech/main")

# Use this for personal projects
VERCEL_PROJECT_ENDPOINT=$(echo "https://api.vercel.com/v1/projects/$VERCEL_PROJECT_ID/env")
# Use this for team projects
# VERCEL_PROJECT_ENDPOINT=$(echo "https://api.vercel.com/v1/projects/$VERCEL_PROJECT_ID/env?teamId=$VERCEL_ORG_ID")

echo "calling... $VERCEL_PROJECT_ENDPOINT"
# We update DATABASE_URL using Vercel API
curl -sS -o - -X POST "$VERCEL_PROJECT_ENDPOINT" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $VERCEL_TOKEN" \
  --data-raw '{
    "target": "preview",
    "gitBranch": "'$VERCEL_GIT_COMMIT_REF'",
    "type": "encrypted",
    "key": "DATABASE_URL",
    "value": "'$BRANCH_URL'"
}' 1>/dev/null

res=$?
echo "res: $res"
if test "$res" != "0"; then
  echo "the curl command failed with: $res"
  exit 0
fi

exit 1
