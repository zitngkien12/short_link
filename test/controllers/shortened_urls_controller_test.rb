require "test_helper"

class ShortenedUrlsControllerTest < ActionDispatch::IntegrationTest
  test "POST /encode returns JSON with shortened URL" do
    post "/encode", params: { url: "https://example.com/articles/123" }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?("short_url")
    assert_match %r{^https?://}, json["short_url"]
  end

  test "POST /decode returns JSON with original URL" do
    shortened = ShortenedUrl.create!(original_url: "https://example.com/articles/123", short_code: "abc123")

    post "/decode", params: { short_url: shortened.short_code }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "https://example.com/articles/123", json["original_url"]
  end

  test "POST /encode requires a URL" do
    post "/encode", params: { url: "" }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_match /is required/i, json["error"]
  end

  test "POST /encode rejects URLs without a valid HTTP(S) host" do
    post "/encode", params: { url: "javascript:alert(1)" }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_match /is invalid/i, json["error"]
  end

  test "POST /decode rejects malformed short codes" do
    post "/decode", params: { short_url: "bad-code!" }, as: :json

    assert_response :not_found
    json = JSON.parse(response.body)
    assert_match /invalid|short code/i, json["error"]
  end

  test "POST /decode rejects URLs from outside the project domain" do
    post "/decode", params: { short_url: "https://example.org/abc123" }, as: :json

    assert_response :not_found
    json = JSON.parse(response.body)
    assert_match /project domain/i, json["error"]
  end

  test "GET /:short_code redirects to the original URL" do
    shortened = ShortenedUrl.create!(original_url: "https://example.com/articles/123", short_code: "abc123")

    get "/#{shortened.short_code}"

    assert_response :redirect
    assert_redirected_to "https://example.com/articles/123"
  end

  test "GET /:short_code caches the original URL for later lookups" do
    shortened = ShortenedUrl.create!(original_url: "https://example.com/articles/123", short_code: "abc123")

    get "/#{shortened.short_code}"

    assert_response :redirect
    assert_equal "https://example.com/articles/123", Rails.cache.read("shortened_url:#{shortened.short_code}")
  end

  test "GET /:short_code returns 404 when the short code does not exist" do
    get "/missing"

    assert_response :not_found
  end
end
