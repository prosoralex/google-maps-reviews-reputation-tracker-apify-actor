#!/usr/bin/env bash
# Run the "Google Maps Reviews Scraper with Sentiment & Replies" Apify Actor synchronously and print the dataset items.
# Usage: export APIFY_TOKEN=your_apify_token && ./run.sh
set -euo pipefail
: "${APIFY_TOKEN:?Set APIFY_TOKEN first (Apify Console > Settings > API & Integrations)}"

curl -sS -X POST "https://api.apify.com/v2/acts/leadsbrary~google-maps-reviews-reputation-tracker/run-sync-get-dataset-items" \
  -H "Authorization: Bearer ${APIFY_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @- <<'JSON'
{
  "placeUrls": [
    "https://www.google.com/maps/place/?q=place_id:ChIJN1t_tDeuEmsRUsoyG83frY4"
  ],
  "maxReviewsPerPlace": 10,
  "maxResults": 3,
  "reviewsSort": "newest",
  "onlyUnanswered": false,
  "onlyWithText": false,
  "language": "en",
  "computeSentiment": true,
  "includeReviewerProfile": false,
  "proxyConfiguration": {
    "useApifyProxy": true
  }
}
JSON
