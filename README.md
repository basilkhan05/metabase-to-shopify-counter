# Metabase to Shopify Counter

This Sinatra app fetches and updates numbers from a given list of URLs and stores them in an SQLite database. It also provides a simple web interface to manage the URLs and display their numbers.

## Features

- Add and remove URLs to fetch data from
- Fetch and update numbers from the specified URLs
- Schedule tasks to fetch and update numbers at regular intervals
- Display a list of URLs and their associated numbers
- Calculate the sum of all numbers

## Prerequisites

- Ruby 2.6 or higher
- Bundler gem

## Setup

1. Clone the repository:

```
git clone https://github.com/basilkhan05/metabase-to-shopify-counter.git
```

2. Change to the project directory:

```
cd metabase-to-shopify-counter
```

3. Install dependencies:

```
bundle install
```

4. Run the application:

```
ruby app.rb
```

6. Open your web browser and navigate to `http://localhost:4567/` to start using the application.

## Usage

1. Add a URL by entering it in the input field and clicking the "Add" button. The URL must return a JSON response with a number.

2. The application will automatically fetch and update the numbers from the specified URLs every 30 seconds.

3. View the list of URLs and their associated numbers by navigating to `http://localhost:4567/`.

4. Remove a URL by clicking the "Delete" button next to the corresponding URL in the list.

5. Get the sum of all numbers by sending a GET request to `http://localhost:4567/sum.json`. The response will be a JSON object containing the sum.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

