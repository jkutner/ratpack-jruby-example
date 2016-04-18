raise "No JDBC_DATABASE_URL found!" unless ENV['JDBC_DATABASE_URL']
DB = Sequel.connect(JdbcUrl.from_database_url)
