class EncodeUrl
  prepend SimpleCommand

  MAX_GENERATION_ATTEMPTS = 5

  def initialize(url)
    @url = url.to_s.strip
  end

  def call
    return errors.add(:url, "is required") if @url.empty?
    return errors.add(:url, "is invalid") unless valid_url?

    record = ShortenedUrl.find_or_initialize_by(original_url: @url)
    if record.new_record?
      begin
        record = create_shortened_url!
      rescue ShortCodeGenerationError
        return errors.add(:url, "could not generate a unique short code")
      end
    end

    { short_url: build_short_url(record.short_code) }
  end

  private

  def valid_url?
    return false if @url.length > ShortenedUrl::MAX_URL_LENGTH

    uri = URI.parse(@url)
    %w[http https].include?(uri.scheme) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end

  def create_shortened_url!
    MAX_GENERATION_ATTEMPTS.times do
      record = ShortenedUrl.new(
        original_url: @url,
        short_code: generate_short_code
      )

      begin
        record.save!
        return record
      rescue ActiveRecord::RecordNotUnique
        next
      end
    end

    raise ShortCodeGenerationError
  end

  def generate_short_code
    SecureRandom.alphanumeric(ShortenedUrl::SHORT_CODE_LENGTH).downcase
  end

  def build_short_url(short_code)
    base_host = ENV.fetch("DEFAULT_HOST", "http://localhost:3000")
    "#{base_host}/#{short_code}"
  end
end

class ShortCodeGenerationError < StandardError; end
