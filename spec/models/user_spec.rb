require 'rails_helper'
require 'active_support'

RSpec.describe User, type: :model do
  before(:each) do
  end

  it "works", focus: false do
    expect(User.count).to eq(0)
  end
end