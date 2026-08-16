require "test_helper"

class ShortenedUrlTest < ActiveSupport::TestCase
  test "short_code must be exactly six lowercase alphanumeric characters" do
    record = ShortenedUrl.new(original_url: "https://example.com", short_code: "abc123!")

    assert_not record.valid?
    assert_includes record.errors[:short_code], "is invalid"
  end

  test "original_url must be a valid HTTP or HTTPS URL with a host" do
    record = ShortenedUrl.new(original_url: "http://", short_code: "abc123")

    assert_not record.valid?
    assert_includes record.errors[:original_url], "must be a valid HTTP or HTTPS URL"
  end

  test "valid shortened URL records are persisted" do
    record = ShortenedUrl.new(original_url: "https://example.com/articles/123", short_code: "abc123")

    assert record.valid?
    assert_difference("ShortenedUrl.count", 1) do
      record.save!
    end
  end
end
