require 'nokogiri'
require 'open-uri'
require 'openssl'
require "sqlite3"

db = SQLite3::Database.new("servers.db")

db.execute <<-SQL
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
while true
  doc = Nokogiri::HTML(open('https://robot.your-server.de/order/market',:ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))
  timestamp = Time.now.to_i
  
  doc.css('div.box_wide').each do |machine|
    entry = {}
    div = machine.css('div.box_content').first
    entry['id'] = div['id'].split('_').last.to_i
    machine.css('td').each do |property|
      key   = property['class'].split('_')[1..-1].join('_')
      value = property.inner_text
      case(key)
      when 'cpu_benchmark' then value = value.to_i
      when 'ram' then value = value.to_f * 1024
      when 'price' then value = value.to_f
      when 'nextreduce' then hours, minutes, rest = value.split(/[^0-9]+/); value = hours.to_i * 60 + minutes.to_i
      end
      entry[key] = value
    end
    db.execute "insert into servers values (?, ?, ?, ?, ?, ?, ?, ?)",
      [entry['id'], 
      entry['cpu'],
      entry['cpu_benchmark'],
      entry['ram'],
      entry['hd'],
      entry['price'],
      entry['nextreduce'],
      timestamp]
  end
  puts "#{Time.now.to_s} - Sleeping 30 minutes until next iteration"
  sleep 30*60
end
