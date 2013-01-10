require 'fileutils'
require "sqlite3"

class ServerAnalyzer
  def initialize(dbfile)  
    @db = SQLite3::Database.new(dbfile)
    FileUtils.mkdir_p('csv')
    @rows = @db.execute( "select * from servers order by timestamp" )
    @now = Time.now

    @days = @rows.group_by do |row|
      timestamp = @row.last
      timestamp = @now - (@now.to_i - timestamp)
      timestamp.to_date
    end

    @row_fields = {}
    @rows.each do |row|
      @row_fields[row] = {}
    end
  end

  def generate_csv(filename)
    raise "Block required by generate_csv!" if not block_given?

    field_values = @rows.map do |row|
      id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp = row
      field_value = yield(id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp)
      @row_fields[row][filename] = field_value
      field_value
    end.uniq.sort_by { |f| f.to_i }

    f = File.open("csv/#{filename}.csv", 'w')
    f_available = File.open("csv/#{filename}_available.csv", 'w')
    f.puts("Date,"+field_values.join(','))
    f_available.puts("Date,"+field_values.join(','))

    @days.each do |day, rows|
      rows_by_field = @rows.group_by do |row|
        id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp = row
        yield(id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp)
      end

      f.print "#{day.to_s}"
      f_available.print "#{day.to_s}"
      field_values.each do |val|
        rows = rows_by_field[val]
        if rows
          prices = rows.map { |row| id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp = row; price }
          f.print ",#{prices.min};#{prices.min};#{prices.max}"
          uniq_servers = rows.map { |row| id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp = row; id }.uniq
          f_available.print ",#{uniq_servers.size}"
        else
          f.print ","
          f_available.print ","
        end
      end
      f.puts
      f_available.puts
    end
    f_available.close
    f.close
  end

  def generate_json
    price_features_by_day = {}
    @row_fields.each do |row, fields|
      id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp = row
      day = (@now - (@now.to_i - timestamp)).to_date
      price_features_by_day[day] ||= {}

    end
  end
end

analyzer = ServerAnalyzer.new("servers.db")

### Disk space ###

analyzer.generate_csv("disksize") do |id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp|
  drivecount = hd[/^\d+ x/].to_i
  size = hd[/\d+(\.\d+)? [GT]B/]
  size, unit = size.split(' ')
  case unit
  when 'GB' then "#{size.to_i * drivecount}GB"
  when 'TB' then "#{(size.to_f * drivecount * 1000).to_i}GB"
  end
end

### Disk count ###
analyzer.generate_csv("diskcount") do |id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp|
  hd[/^\d+ x/].to_i
end

### Benchmark score ###
analyzer.generate_csv("benchmark") do |id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp|
  lower = Math.sqrt(cpu_benchmark).to_i / 5
  upper = lower + 1
  "#{(lower*5)**2}-#{(upper*5)**2}"
end

### Availiable RAM ###
analyzer.generate_csv("ram") do |id, cpu, cpu_benchmark, ram, hd, price, nextreduce, timestamp|
  ram
end

### JSON for dynamic filtering ###
analyzer.generate_json()