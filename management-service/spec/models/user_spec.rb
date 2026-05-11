require 'rails_helper'

RSpec.describe User, type: :model do
  it "is valid with valid attributes" do
    user = User.new(
      name: "Test User",
      email: "test@example.com",
      password: "password123"
    )
    expect(user).to be_valid
  end

  it "is invalid without an email" do
    user = User.new(email: nil)
    expect(user).to_not be_valid
  end

  it "is invalid with a duplicate email" do
    User.create!(name: "User 1", email: "dup@example.com", password: "password")
    user2 = User.new(name: "User 2", email: "dup@example.com", password: "password")
    expect(user2).to_not be_valid
  end
end
