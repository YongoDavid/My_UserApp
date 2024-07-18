require 'sqlite3'

class User
  DB_NAME = "db.sql"

  def initialize
    @db = SQLite3::Database.new(DB_NAME)
    @db.results_as_hash = true

    # Check if the users table exists
    table_exists = @db.get_first_value("SELECT name FROM sqlite_master WHERE type='table' AND name='users';")

    # Create the users table if it does not exist
    unless table_exists
      @db.execute <<-SQL
        CREATE TABLE users (
          id INTEGER PRIMARY KEY,
          firstname TEXT,
          lastname TEXT,
          age INTEGER,
          password TEXT,
          email TEXT
        );
      SQL
    end
  end

  def create(user_info)
    puts "Creating User: #{user_info.inspect}" # Debugging statement
    @db.execute("INSERT INTO users (firstname, lastname, age, password, email) VALUES (?, ?, ?, ?, ?)",
                user_info[:firstname], user_info[:lastname], user_info[:age], user_info[:password], user_info[:email])
    @db.last_insert_row_id
  end

  def find(user_id)
    @db.get_first_row("SELECT * FROM users WHERE id = ?", user_id)
  end

  def find_by_email(email)
    result = @db.get_first_row("SELECT * FROM users WHERE email = ?", email)
    puts "find_by_email: Searching for email #{email}, Result: #{result.inspect}" # Debugging output
    result
  end

  def all
    users = []
    @db.execute("SELECT * FROM users") do |row|
      users << { id: row['id'], firstname: row['firstname'], lastname: row['lastname'], age: row['age'], email: row['email'] }
    end
    users
  end

  def update(user_id, attribute, value)
    @db.execute("UPDATE users SET #{attribute} = ? WHERE id = ?", value, user_id)
    find(user_id)
  end

  def destroy(user_id)
    @db.execute("DELETE FROM users WHERE id = ?", user_id)
  end
end