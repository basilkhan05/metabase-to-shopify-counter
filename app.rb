require "sinatra/base"
require "sqlite3"
require "json"
require "rufus-scheduler"
require "httparty"

class MetabaseToShopifyCounter < Sinatra::Base
  # Set up SQLite database connection
  configure do
    db = SQLite3::Database.new "data.db"
    db.execute "CREATE TABLE IF NOT EXISTS urls (id INTEGER PRIMARY KEY, url TEXT)"
    db.execute "CREATE TABLE IF NOT EXISTS numbers (id INTEGER PRIMARY KEY, url_id INTEGER, number REAL)"
    set :db, db
  end

  # Define method to fetch numbers from URL and update database
  def self.fetch_and_update_numbers(url, db)
    response = HTTParty.get(url)
    json_response = JSON.parse(response.body)
    number = json_response[0]["number"].to_f.round(2)

    # Get URL ID from database
    result = db.execute("SELECT id FROM urls WHERE url = ? LIMIT 1", url)
    url_id = result[0]

    if url_id
      # Check if url_id exists in the numbers table
      existing_number = db.execute("SELECT * FROM numbers WHERE url_id = ?", url_id[0]).first
      if existing_number
        # Update number in database
        db.execute "UPDATE numbers SET number = ? WHERE url_id = ?", [number, url_id[0]]
      else
        db.execute "INSERT INTO numbers (url_id, number) VALUES (?, ?)", [url_id[0], number]
      end
    else
      # Insert new URL and number into database
      db.execute "INSERT INTO urls (url) VALUES (?)", url
      url_id = db.last_insert_row_id
      db.execute "INSERT INTO numbers (url_id, number) VALUES (?, ?)", [url_id, number]
    end
  end

  # Schedule task to fetch and update numbers every minute during business hours
  scheduler = Rufus::Scheduler.new
  scheduler.every "5s" do
    db = SQLite3::Database.open "data.db"
    urls = db.execute("SELECT url FROM urls")
    puts "Fetching and updating numbers for #{urls.count} URLs..."
    urls.each do |url|
      MetabaseToShopifyCounter.fetch_and_update_numbers(url[0], db) # call method on instance
    end
  end

  # Define endpoint to add URLs using HTML form and display URLs in the database
  get "/" do
    db = SQLite3::Database.open "data.db"

    # Fetch all URL and corresponding number using a single query
    query = <<-SQL
      SELECT urls.id, urls.url, numbers.number
      FROM urls
      LEFT JOIN numbers ON urls.id = numbers.url_id
    SQL

    result = db.execute(query)

    # Prepare the data for the template
    data = result.map { |row| {id: row[0], url: row[1], number: row[2]} }

    erb :index, locals: {data: data}
  end

  post "/add" do
    url = params[:url]
    db = SQLite3::Database.open "data.db"
    db.execute "INSERT INTO urls (url) VALUES (?)", url
    redirect "/"
  end

  # Define endpoint to remove URLs from the database
  post "/urls/:id/delete" do
    id = params[:id]
    db = SQLite3::Database.open "data.db"
    db.execute "DELETE FROM urls WHERE id = ?", id
    db.execute "DELETE FROM numbers WHERE url_id = ?", id
    redirect "/"
  end

  # Define endpoint to get the sum of all numbers
  get "/sum*.*" do |_, ext|
    content_type :json
    db = SQLite3::Database.open "data.db"
    result = db.execute "SELECT SUM(number) FROM numbers"
    {number: result[0][0]&.round || 0}.to_json
  end
end
