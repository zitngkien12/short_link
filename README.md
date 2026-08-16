# Short Link

A Rails API for generating short links and redirecting from a short code to the original URL.

## Requirements

Before setting up the project on a new machine, install:

- Ruby 3.2 or newer
- Bundler
- PostgreSQL
- Redis
- Git

## 1) Clone the project

```bash
git clone git@github.com:zitngkien12/short_link.git
cd short_link
```

You can also use HTTPS instead:

```bash
git clone https://github.com/zitngkien12/short_link.git
``` 

## 2) Install Ruby dependencies

```bash
bundle install
```

If Bundler reports missing native extensions, install the required OS packages for Ruby, PostgreSQL, and Redis first.

## 3) Configure environment variables

Create a `.env` file in the project root:

```bash
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/short_link_development"
DEFAULT_HOST="http://localhost:3000"
REDIS_URL="redis://localhost:6379/0"
```

If you want to use a different database or host, update those values accordingly.

## 4) Start PostgreSQL and Redis

Make sure PostgreSQL and Redis are running locally.

### PostgreSQL

```bash
createdb short_link_development
```

### Redis

```bash
redis-server
```

If Redis is not installed locally, use Docker:

```bash
docker run --name short-link-redis -p 6379:6379 -d redis:7
```

## 5) Create and migrate the database

```bash
bin/rails db:create db:migrate
```

Optional:

```bash
bin/rails db:seed
```

## 6) Run the app

```bash
bin/rails server
```

Open:

```text
http://localhost:3000
```

## 7) API endpoints

### Encode a long URL

```bash
curl -X POST http://localhost:3000/encode \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com/articles/123"}'
```

Example response:

```json
{
  "short_url": "http://localhost:3000/abc123"
}
```

### Decode a short URL

```bash
curl -X POST "http://localhost:3000/decode?short_url=http://localhost:3000/abc123"
```

Example response:

```json
{
  "original_url": "https://example.com/articles/123"
}
```

### Redirect from short URL to original URL

```bash
curl -I http://localhost:3000/abc123
```

If the short code exists, this redirects to the original URL. If it does not exist, the app returns 404.

## 8) Run tests

```bash
bin/rails test
```

Or the project-specific controller tests:

```bash
bundle exec ruby -Itest test/controllers/shortened_urls_controller_test.rb
```

## Troubleshooting

- If `bundle install` fails, install the required system packages for Ruby/PostgreSQL.
- If the app cannot connect to PostgreSQL, verify `DATABASE_URL` and that PostgreSQL is running.
- If the app cannot connect to Redis, verify `REDIS_URL` and that Redis is running.
- If redirects fail, make sure `DEFAULT_HOST` matches the domain where the app is being served.

## Security considerations

- Only accept HTTP and HTTPS URLs, and reject values without a valid hostname.
- Limit URL length to 2,048 characters to keep the database and HTTP stack safe.
- Shorteners are exposed to open redirect and phishing risks by design; in production, add a domain allowlist, blacklist, or a service such as Google Safe Browsing for risky destinations.
- Add rate limiting for both `/encode` and `/decode` endpoints to reduce abuse and brute-force enumeration.
- Prevent enumeration of valid short codes by limiting request volume and monitoring repeated failures.
- Do not fetch destination URLs from the server side; avoid SSRF by not making outbound requests to arbitrary targets.
- Avoid logging full URLs when they may contain tokens, query strings, or sensitive data.
- Apply request-body limits, timeouts, and retry budgets for external integrations.
- Validate the domain on decode when using a full short URL and verify the host against the configured project domain.
- Run production behind HTTPS, add security headers, and enable monitoring and alerting for suspicious access patterns.

## Scalability and collision handling

- The current space is $36^6$, which is about 2.18 billion possible short codes when using lowercase letters and digits.
- A unique database index remains the final protection against duplicate short codes under concurrency.
- Catch `ActiveRecord::RecordNotUnique` and retry with a bounded number of attempts instead of looping forever.
- For higher traffic, use stateless Rails instances behind a load balancer, PostgreSQL for the authoritative data store, and Redis for hot cache entries.
- If traffic grows, increase the code length to 8–10 characters or switch to a Base62 identifier generated from a database sequence.
- Indexing on `short_code` keeps lookups close to $O(\log n)$ in the database and makes redirect lookups efficient.
- Apply rate limiting and caching for URLs that are accessed frequently.

## Notes

This project uses:

- Rails
- PostgreSQL
- Redis cache
- JSON API endpoints
