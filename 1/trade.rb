require 'rexml/document'
require 'csv'
require 'bigdecimal'

class Trade
  def self.total item, currency
    prices = Trade.get_item_price item
    conv = Trade.convert prices, currency
    total = conv.inject(BigDecimal.new(0)){|sum, pr| sum + pr}.round(2, :banker).to_s('F')
    File.open('OUTPUT.txt', 'w') { |f| f.puts total } 
  end

  def self.get_item_price item 
    stocks = []
    CSV.foreach("TRANS.csv", headers: true) do |row|
      stocks << row['amount'] if row['sku'] == item
    end 
    stocks
  end 

  def self.load_rates
    rates = {}
    file = File.new("RATES.xml")
    doc = REXML::Document.new file
    doc.elements.to_a('//rates/rate').each do |el|
      from = el.elements["from"].first.to_s
      to = el.elements["to"].first.to_s
      rate = el.elements["conversion"].first.to_s
      rates[from] = { to => rate }
    end
    rates
  end

  def self.find_path rates, search, path=[] 
    dist = [] 
    rates.each_key do |k|
      dist[k] = Float::INFINITY
    end
  end

  def self.convert prices, currency
    res = []
    rates = Trade.load_rates
    puts rates
    rate = ""
    prices.each do |pr|
      cost, item_cur = pr.split(' ')
      cost = BigDecimal.new cost
      if item_cur != currency 
        exchange = rates[item_cur]
        if exchange[currency]
          rate  = BigDecimal.new(exchange[currency]).round(2, :banker)
        else
          exchange.each_key do |val|
            if rates[val] && rates[val][currency]
              rate =  BigDecimal.new(exchange[val]) * BigDecimal.new(rates[val][currency])
              break
            end
          end
        end
        cost *= rate
      end
      res << cost.round(2, :banker)
    end
    res
  end

end

Trade.total "DM1182", "USD" 
