require 'rails_helper'

RSpec.describe "Addresses", type: :request do
  let(:user) { User.create!(name: "Admin", email: "admin@test.com", password: "password") }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /addresses" do
    it "returns unauthorized without token" do
      get "/addresses"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns success with valid token" do
      get "/addresses", headers: headers
      expect(response).to have_http_status(:success)
    end
  end
end
