class ShortenedUrlsController < ApplicationController
  def encode
    command = EncodeUrl.call(params[:url])

    if command.success?
      render json: command.result, status: :ok
    else
      render json: { error: command.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def decode
    command = DecodeUrl.call(params[:short_url] || params[:url])

    if command.success?
      render json: command.result, status: :ok
    else
      render json: { error: command.errors.full_messages.to_sentence }, status: :not_found
    end
  end

  def redirect
    original_url = Rails.cache.fetch("shortened_url:#{params[:short_code]}", expires_in: 1.hour) do
      ShortenedUrl.find_by(short_code: params[:short_code])&.original_url
    end

    return head :not_found if original_url.nil?

    redirect_to original_url, allow_other_host: true
  end
end
