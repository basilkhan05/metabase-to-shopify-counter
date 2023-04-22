require_relative "spec_helper"

describe MetabaseToShopifyCounter do
  include Rack::Test::Methods

  def app
    MetabaseToShopifyCounter
  end

  # Helper method to stub the response from the URL
  def stub_url_response(url, number)
    response_body = JSON.generate([{"number" => number}])
    stub_request(:get, url).to_return(status: 200, body: response_body, headers: {})
  end

  it "renders the index page" do
    get "/"
    expect(last_response).to be_ok
    expect(last_response.body).to include("Add")
    expect(last_response.body).to include("URLs")
  end

  it "adds a new URL" do
    post "/add", url: "http://example.com"
    follow_redirect!
    expect(last_request.path).to eq("/")
  end

  let(:unique_url) { "http://example.com/#{SecureRandom.hex}" }

  it "returns the sum of all numbers" do
    get "/sum.json"
    expect(last_response).to be_ok
    expect(JSON.parse(last_response.body)).to have_key("number")
  end

  it "fetches and updates numbers" do
    url = "http://example.com"
    number = 42.42
    stub_url_response(url, number)

    app.settings.db.execute "INSERT INTO urls (url) VALUES (?)", url
    url_id = app.settings.db.last_insert_row_id

    MetabaseToShopifyCounter.fetch_and_update_numbers(url, app.settings.db)

    result = app.settings.db.execute "SELECT number FROM numbers WHERE url_id = ?", url_id
    expect(result[0][0]).to eq(number)
  end

  it "updates numbers in the scheduler" do
    url = "http://example.com"
    initial_number = 42.42
    updated_number = 45.45
    stub_url_response(url, initial_number)

    app.settings.db.execute "INSERT INTO urls (url) VALUES (?)", url
    url_id = app.settings.db.last_insert_row_id

    MetabaseToShopifyCounter.fetch_and_update_numbers(url, app.settings.db)

    # Simulate scheduler updating the numbers
    stub_url_response(url, updated_number)
    MetabaseToShopifyCounter.fetch_and_update_numbers(url, app.settings.db)

    result = app.settings.db.execute "SELECT number FROM numbers WHERE url_id = ?", url_id
    expect(result[0][0]).to eq(updated_number)
  end
end
