class DecodeUrl
  prepend SimpleCommand

  def initialize(short_url)
    @short_url = short_url.to_s.strip
  end

  def call
    return errors.add(:short_url, "is required") if @short_url.empty?

    short_code = extract_short_code(@short_url)
    return errors.add(:short_url, "has an invalid short code") unless valid_short_code?(short_code)
    return errors.add(:short_url, "must belong to the project domain") unless valid_project_domain?

    original_url = Rails.cache.fetch("shortened_url:#{short_code}", expires_in: 1.hour) do
      ShortenedUrl.find_by(short_code: short_code)&.original_url
    end

    return errors.add(:short_url, "not found") if original_url.nil?

    { original_url: original_url }
  end

  private

  def valid_short_code?(value)
    value.match?(ShortenedUrl::SHORT_CODE_FORMAT)
  end

  def valid_project_domain?
    return true if @short_url.match?(ShortenedUrl::SHORT_CODE_FORMAT)

    uri = URI.parse(@short_url)
    return false if uri.host.blank?

    project_host = URI.parse(ENV.fetch("DEFAULT_HOST", "http://localhost:3000")).host
    [project_host, "localhost", "127.0.0.1"].include?(uri.host)
  rescue URI::InvalidURIError
    false
  end

  def extract_short_code(value)
    return value if value.match?(ShortenedUrl::SHORT_CODE_FORMAT)

    uri = URI.parse(value)
    if uri.host.present?
      uri.path.sub(%r{^/}, "")
    else
      value.sub(%r{^/}, "")
    end
  rescue URI::InvalidURIError
    value.sub(%r{^/}, "")
  end
end
