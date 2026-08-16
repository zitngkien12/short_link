require 'swagger_helper'

RSpec.describe 'Shortened URLs API', type: :request do
  path '/encode' do
    post 'Encodes a URL to a shortened URL' do
      tags 'Shortened URLs'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :url, in: :query, type: :string, required: true, description: 'Original URL to shorten'

      response '200', 'successful' do
        let(:url) { 'https://example.com/articles/123' }

        run_test!
      end

      response '422', 'invalid URL' do
        let(:url) { 'not-a-valid-url' }

        run_test!
      end
    end
  end

  path '/decode' do
    post 'Decodes a shortened URL to its original URL' do
      tags 'Shortened URLs'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :short_url, in: :query, type: :string, required: true, description: 'Shortened URL to decode'

      response '200', 'successful' do
        let(:short_url) { "#{ENV.fetch('DEFAULT_HOST', 'http://localhost:3000')}/abc123" }

        before do
          ShortenedUrl.create!(original_url: 'https://example.com/articles/123', short_code: 'abc123')
        end

        run_test!
      end

      response '404', 'not found' do
        let(:short_url) { "#{ENV.fetch('DEFAULT_HOST', 'http://localhost:3000')}/missing" }

        run_test!
      end
    end
  end
end
