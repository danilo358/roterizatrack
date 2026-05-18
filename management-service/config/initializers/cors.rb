Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*' # Em produção, mude para o domínio do seu front-end
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end