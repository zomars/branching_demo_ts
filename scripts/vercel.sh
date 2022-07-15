git clone https://github.com/stedolan/jq.git
cd jq
autoreconf -i
./configure --disable-maintainer-mode
make
make install

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
BRANCH_NAME=$(curl -o - -X POST -H "Authorization: Bearer $NEON_API_TOKEN" https://console.neon.tech/api/v1/projects/$NEON_PG_CLUSTER/branches | jq -r '.id')

echo "Branch name: $BRANCH_NAME"

if [ "$BRANCH_NAME" == "" ]; then
  exit 0
fi

# switch to branch
BRANCH_URL=$(postgres://$NEON_PG_CREDENTIALS@$BRANCH_NAME.cloud.neon.tech/main)

echo "calling... https://api.vercel.com/v1/projects/$VERCEL_PROJECT_ID/env?teamId=$VERCEL_ORG_ID"
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

res=$?
echo "res: $res"
if test "$res" != "0"; then
  echo "the curl command failed with: $res"
  exit 0
fi
