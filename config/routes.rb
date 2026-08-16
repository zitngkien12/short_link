Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  post "/encode", to: "shortened_urls#encode"
  post "/decode", to: "shortened_urls#decode"
  get "/:short_code", to: "shortened_urls#redirect", as: :shortened_url

  get "up" => "rails/health#show", as: :rails_health_check
end
