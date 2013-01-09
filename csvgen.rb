require 'fileutils'
require "sqlite3"

db = SQLite3::Database.new("servers.db")
FileUtils.mkdir_p('csv')
rows = db.execute( "select* from servers order by timestamp" )

days = rows.group_by do |row|
  timestamp = row.last
  now = Time.now
  timestamp = now - (now.to_i - timestamp)
  timestamp.to_date
end

### Disk space ###

def parse_hdd_storage(hd)
  drivecount = hd[/^\d+ x/].to_i
  size = hd[/\d+(\.\d+)? [GT]B/]
  size, unit = size.split(' ')
  case unit
  when 'GB' then return size.to_i * drivecount
  when 'TB' then return (size.to_f * drivecount * 1000).to_i
  end
end

disk_spaces = rows.map do |row|
  id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp = row
  parse_hdd_storage(hd)
end.uniq.sort

f = File.open('csv/disksize.csv', 'w')
f.puts("Date,"+disk_spaces.map { |s| "#{s}GB" }.join(','))

days.each do |day, rows|
  rows_by_space = rows.group_by do |row|
    id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp = row
    parse_hdd_storage(hd)
  end

  f.print "#{day.to_s}"
  disk_spaces.each do |space|
    rows = rows_by_space[space]
    if rows
      prices = rows.map { |row| id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp = row; price }
      f.print ",#{prices.min};#{prices.min};#{prices.max}"
    else
      f.print ","
    end
  end
  f.puts
end
f.close

### Disk count ###
disk_counts = rows.map do |row|
  id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp = row
  hd[/^\d+ x/].to_i
end.uniq.sort

f = File.open('csv/diskcount.csv', 'w')
f.puts("Date,"+disk_counts.join(','))

days.each do |day, rows|
  rows_by_space = rows.group_by do |row|
    id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp = row
    hd[/^\d+ x/].to_i
  end

  f.print "#{day.to_s}"
  disk_counts.each do |disks|
    rows = rows_by_space[disks]
    prices = rows.map { |row| id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp = row; price }
    f.print ",#{prices.min};#{prices.min};#{prices.max}"
  end
  f.puts
end
f.close
