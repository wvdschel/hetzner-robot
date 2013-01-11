orig_file   = 'servers.db'
new_file    = "new_#{orig_file}"
backup_file = "#{Time.now.to_i}_#{orig_file}"

File.copy(orig_file, backup_file)
db = SQLite3::Database.new(orig_file)
rows = @db.execute( "select * from servers order by timestamp" )
new_db = SQLite3::Database.new(new_file)

new_db.execute <<-SQL
  create table if not exists servers (
  	id integer,
    cpu text,
    cpu_benchmark integer,
    ram integer,
    hdd text,
    price integer,
    reduction_timer integer,
    timestamp integer
  );
SQL
rows.each { |row| new_db.execute("insert into servers values (?, ?, ?, ?, ?, ?, ?, ?)", row) }
db.close
new_db.close

File.rename(new_file, orig_file)