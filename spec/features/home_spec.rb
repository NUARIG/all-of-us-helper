require 'rails_helper'
RSpec.feature 'Repositories', type: :feature do
  before(:each) do
    visit root_path
    sleep(1)
  end

  scenario 'works', js: true, focus: true do
    expect(page).to have_css('#all-of-us-helper-content #home', text: 'Thank you for your interest in All of Us Helper')
  end
end