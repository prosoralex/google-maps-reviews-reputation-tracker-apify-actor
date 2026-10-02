# Google Maps Reviews Scraper with Sentiment & Replies — Apify Actor usage guide

[![Run on Apify](https://img.shields.io/badge/Apify-Run%20this%20Actor-24C1E0)](https://apify.com/leadsbrary/google-maps-reviews-reputation-tracker?fpr=aupara)
[![Try Apify free](https://img.shields.io/badge/Apify-Try%20it%20free-24C1E0)](https://console.apify.com/sign-up?fpr=aupara)

Scrape Google Maps reviews with star rating, text, date, reviewer name, owner-reply detection, reply latency in days and star-anchored sentiment. Filter unanswered or by star rating. Export to JSON, CSV or Excel. From $0.18 per 1,000 results.

> **This repository does not contain the Actor's source code.** The Actor is closed-source and
> runs on Apify's infrastructure. This repo is documentation plus ready-to-run client examples
> (curl, Python, JavaScript) that call the hosted Actor with **your own** Apify API token.

**Run it on Apify →** [https://apify.com/leadsbrary/google-maps-reviews-reputation-tracker?fpr=aupara](https://apify.com/leadsbrary/google-maps-reviews-reputation-tracker?fpr=aupara)

## What it does

This Actor collects the publicly visible reviews shown on a Google Maps place page (one or many places per run) and, for each review, computes the fields a reputation-management workflow actually needs:

- Whether the owner replied, and how long it took (`ownerReplied`, `ownerReplyText`, `replyLatencyDays`). Google exposes no exact timestamp for replies, only a coarse relative label (e.g. "a week ago"); `replyLatencyDays` is therefore an approximation whose error grows with the reply's age, and `null` when it can't be placed reliably.
- A sentiment label and score derived from the star rating (plus a lexicon fallback for common English words), so you don't need to call an LLM or a sentiment API per review.
- A `needsResponse` flag: `true` when a review is negative/neutral **and** unanswered — the exact triage filter an agency needs.
- Server-side filters (`onlyUnanswered`, `minStars`/`maxStars`, `reviewsNewerThan`) so you pay only for the reviews that matter to you.

Most low-cost Google Maps review scrapers return the raw star/text/date dump and leave sentiment, reply-matching and latency to you. This Actor does that work locally, for free, as part of the same run.

Each run returns up to **60 of the newest reviews per place** (Google's own review-list response is capped at 60 regardless of what you request — see FAQ). This is designed for recurring reputation monitoring (schedule a run + `reviewsNewerThan`), not a one-off full historical export.

## Use cases

- Weekly reputation report per location: rating trend, sentiment mix, count of unanswered reviews, median owner reply latency.
- Agency SLA tracking: list every negative review with ownerReplied=false older than N days, per client location.
- Feed sentiment-tagged, reply-aware reviews into an AI agent / RAG pipeline that drafts owner responses for the reviews that still need one.
- Competitive benchmark: compare sentiment mix and reply responsiveness of a business against nearby competitors' public reviews.


## Input

| Field | Type | Required | Description |
|---|---|---|---|
| `placeUrls` | array | yes | Google Maps place URLs whose public reviews to collect (accepts both the `?q=place_id:...` form and the `@lat,lng/data=...!1s0x...` form). At least one is required. |
| `maxReviewsPerPlace` | integer | no | Maximum reviews collected per place. Google's review-list endpoint returns at most 60 reviews in a single response regardless of this value (a confirmed server-side cap — see README), so this is also the practical ceiling per place per run. |
| `maxResults` | integer | no | Hard cap on total reviews pushed to the dataset across all places; the run stops cleanly once reached (also protects your spending). |
| `reviewsSort` | string | no | Sort order requested from Google. 'newest' is the default because reputation monitoring is time-based. |
| `reviewsNewerThan` | string | no | Skip reviews published before this date (ISO date, e.g. 2026-09-01, or a relative age like '30 days'). Pagination stops early when reviewsSort=newest, lowering cost for recurring monitoring runs. |
| `minStars` | integer | no | Keep only reviews with at least this many stars. |
| `maxStars` | integer | no | Keep only reviews with at most this many stars — e.g. 3 to triage detractors. |
| `onlyUnanswered` | boolean | no | Keep only reviews with no public owner response. |
| `onlyWithText` | boolean | no | Skip star-only reviews with no text (nothing to analyse or answer). |
| `language` | string | no | Interface/response language requested from Google (ISO 639-1, e.g. 'en', 'fr', 'es'). Affects relative date strings and owner-reply labels. |
| `computeSentiment` | boolean | no | Compute sentiment label/score locally (star-anchored rules, no external API, no extra cost). Disable for a pure raw dump. |
| `includeReviewerProfile` | boolean | no | Include the reviewer's public profile URL and contribution count. Off by default for data minimisation (GDPR). |
| `proxyConfiguration` | object | no | Apify Proxy settings. Datacenter proxy is proven sufficient for this target; escalate to residential only if you see repeated blocks. |

The full input form (with defaults and validation) is on the [Actor page](https://apify.com/leadsbrary/google-maps-reviews-reputation-tracker?fpr=aupara).


## Output (sample item)

Sample trimmed for readability (long texts and lists are shortened) — a real run returns the complete data.

```json
{
  "placeUrl": "https://www.google.com/maps/place/?q=place_id:ChIJrTLr-GyuEmsRBfy61i59si0",
  "placeId": "ChIJrTLr-GyuEmsRBfy61i59si0",
  "skipped": false,
  "skipReason": null,
  "reviewId": "Ci9DQUlRQUNvZENodHljRjlvT2xWdVUzTXlTbUY0U1hwSFF6SkNNbWx2YW1sdFZrRRAB",
  "reviewUrl": "https://www.google.com/maps/reviews/data=!4m8!14m7!1m6!2m5!1sCi9DQUlRQUNvZENodHljRjlvT2xWdVUzTXlTbUY0U1hwSFF6SkNNbWx2YW1sdFZrRRAB!2m1!1s0x0:0x2db27d2ed6bafc05!3m1!1s2@1:CAIQACodChtycF9oOlVuU3MySmF4SXpHQzJCMmlvamltVkE%7C%7C?hl=en-US",
  "stars": 4,
  "text": "Great service and experience. I wish the menu was less focused on sea food and a bit more variety. Recommended.",
  "textLanguage": "en",
  "publishedAtDate": "2026-07-06T09:19:28.897Z",
  "publishedAtText": "2 months ago",
  "daysSincePublished": 88,
  "likesCount": 0,
  "reviewerName": "Raph",
  "reviewerIsLocalGuide": false,
  "reviewerReviewsCount": null,
  "reviewerProfileUrl": null,
  "ownerReplied": true,
  "ownerReplyText": "Thanks so much for your kind words! We're delighted you had a great experience with us. We also appreciate your feedback about the menu; we'll certainly pass on to our team for consideration.",
  "ownerReplyPublishedAtDate": "2026-08-03T09:58:34.381Z",
  "replyLatencyDays": 28,
  "sentiment": "positive",
  "sentimentScore": 0.45,
  "sentimentMethod": "stars+lexicon",
  "needsResponse": false,
  "scrapedAt": "2026-10-02T09:58:34.381Z"
}
```

## Pricing

Pay only for results: about **$0.27 per 1,000 results** on the Apify Free plan, down to **$0.18 per 1,000** on paid Apify plans.

Apify platform usage (compute) is billed by Apify on top of the per-result price — about **$0.02 per 1,000 results** in our measured test runs (estimate, varies with input). Tip: keep only the output formats and options you need to reduce it.

Prices can change — the [Actor page](https://apify.com/leadsbrary/google-maps-reviews-reputation-tracker?fpr=aupara) always shows the current pricing.

## Quick start

You need an Apify account and an API token (Apify Console → **Settings → API & Integrations**).
Never commit your token: export it as the `APIFY_TOKEN` environment variable.

### cURL

```bash
curl -X POST "https://api.apify.com/v2/acts/leadsbrary~google-maps-reviews-reputation-tracker/run-sync-get-dataset-items" \
  -H "Authorization: Bearer $APIFY_TOKEN" \
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
```

### Python (`apify-client`)

```python
import os
from apify_client import ApifyClient

client = ApifyClient(os.environ["APIFY_TOKEN"])

run_input = {
    "placeUrls": [
        "https://www.google.com/maps/place/?q=place_id:ChIJN1t_tDeuEmsRUsoyG83frY4"
    ],
    "maxReviewsPerPlace": 10,
    "maxResults": 3,
    "reviewsSort": "newest",
    "onlyUnanswered": False,
    "onlyWithText": False,
    "language": "en",
    "computeSentiment": True,
    "includeReviewerProfile": False,
    "proxyConfiguration": {
        "useApifyProxy": True
    }
}

run = client.actor("leadsbrary/google-maps-reviews-reputation-tracker").call(run_input=run_input)
for item in client.dataset(run["defaultDatasetId"]).iterate_items():
    print(item)
```

### JavaScript (`apify-client`)

```javascript
import { ApifyClient } from 'apify-client';

const client = new ApifyClient({ token: process.env.APIFY_TOKEN });

const runInput = {
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
};

const run = await client.actor('leadsbrary/google-maps-reviews-reputation-tracker').call(runInput);
const { items } = await client.dataset(run.defaultDatasetId).listItems();
console.log(items);
```

Runnable versions live in [`examples/`](./examples).

## Troubleshooting

- **401 / "User was not found or authentication token is not valid"** — check that `APIFY_TOKEN` is set and copied completely.
- **The run finished but the dataset is empty** — widen your search input or check the run log on the Apify Console.
- **Run stops early** — you may have reached the maximum cost per run you set in Apify; raise it in the run options.
- **Need something else?** Open an issue in this repository or use the Issues tab on the Actor page.

## Don't have an Apify account yet?

[Sign up here](https://console.apify.com/sign-up?fpr=aupara) — new accounts get $5 of free platform usage every month, enough to try most Actors without paying upfront.
Browse the full [Apify Store](https://apify.com/store?fpr=aupara) or [all Actors from this developer](https://apify.com/leadsbrary?fpr=aupara).

## Links

- Actor page: [https://apify.com/leadsbrary/google-maps-reviews-reputation-tracker?fpr=aupara](https://apify.com/leadsbrary/google-maps-reviews-reputation-tracker?fpr=aupara)
- All Actors from this developer: [https://apify.com/leadsbrary?fpr=aupara](https://apify.com/leadsbrary?fpr=aupara)
- Apify API reference: [https://docs.apify.com/api/v2](https://docs.apify.com/api/v2)

## Keywords

google maps reviews scraper, google reviews sentiment analysis, google maps reputation tracker, review response tracker, unanswered google reviews, owner reply latency, google reviews api alternative, local seo review monitoring, multi location review export, google business profile reviews export, review sentiment csv export, scrape google reviews without api key

#GoogleMaps #GoogleReviews #ReviewScraper #ReputationManagement #LocalSEO #SentimentAnalysis #LeadGeneration #WebScraping #Apify #CustomerFeedback #MultiLocation

## License

The example code in this repository is released under the MIT License — see [LICENSE](./LICENSE).
It does not cover the Actor itself, which remains closed-source and is operated by its developer on Apify.
