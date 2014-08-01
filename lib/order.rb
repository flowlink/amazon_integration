class Order
  attr_accessor :amazon_tax,
                  :gift_wrap,
                  :gift_wrap_tax,
                  :items_total,
                  :last_update_date,
                  :line_items,
                  :number,
                  :order_hash,
                  :promotion_discount,
                  :shipping_discount,
                  :shipping_total,
                  :status

  def initialize(order_hash, config)
    puts "initialize: #{order_hash.inspect}"
    @line_items         = []
    @order_hash         = order_hash
    # @config             = config
    @number             = order_hash['AmazonOrderId']
    # @order_total        = order_hash['OrderTotal']['Amount']
    @last_update_date   = order_hash['LastUpdateDate']
    @status             = order_hash['OrderStatus']
    @shipping_total     = 0.00
    @shipping_discount  = 0.00
    @promotion_discount = 0.00
    @amazon_tax         = 0.00
    @gift_wrap          = 0.00
    @gift_wrap_tax      = 0.00
    @items_total        = 0.00
  end

  def to_message
    puts "#to_message: #{@order_hash.inspect} #{self.inspect}"
    roll_up_item_values
    items_hash       = assemble_line_items
    # address_hash     = assemble_address
    totals_hash      = assemble_totals_hash
    adjustments_hash = assemble_adjustments_hash
    shipment_hash    = assemble_shipment_hash(items_hash)

    {
      id: @number,
      number: @number,
      channel: @order_hash['SalesChannel'],
      # currency: @order_hash['OrderTotal']['CurrencyCode'],
      status: @order_hash['OrderStatus'],
      placed_on: @order_hash['PurchaseDate'],
      updated_at: @order_hash['LastUpdateDate'],
      email: @order_hash['BuyerEmail'],
      totals: totals_hash,
      adjustments: adjustments_hash,
      line_items: items_hash,
      payments: [{
        amount: @order_total,
        payment_method: 'Amazon',
        status: 'complete'
      }],
      shipments: shipment_hash#,
      # shipping_address: address_hash,
      # billing_address: address_hash
    }
  end

  private

  def assemble_line_items
    @line_items.collect &:to_h
  end

  def assemble_address
    # Sometimes Amazon can respond with null address1. It is invalid for the integrator
    # The property '#/order/shipping_address/address1' of type NilClass did not match the following type:
    # string in schema augury/lib/augury/validators/schemas/address.json#
    # ['shipping_address']['address_line1'].to_s
    # "shipping_address": {
    #   "address1": null
    #
    # @order_hash['buyer_name'].to_s buyer_name can be nil as well
    firstname, lastname = shipping_address_names
    address1,  address2 = shipping_addresses

    { firstname:  firstname,
      lastname:   lastname,
      address1:   address1.to_s,
      address2:   address2.to_s,
      city:       @order_hash['ShippingAddress']['City'],
      zipcode:    @order_hash['ShippingAddress']['PostalCode'],
      phone:      order_phone_number,
      country:    @order_hash['ShippingAddress']['CountryCode'],
      state:      order_full_state }
  end

  def shipping_address_names
    names = @order_hash['ShippingAddress']['Name'].to_s.split(' ')
    # Pablo Henrique Sirio Tejero Cantero
    # => ["Pablo", "Henrique Sirio Tejero Cantero"]
    [names.first.to_s,            # Pablo
     names[1..-1].to_a.join(' ')] # Henrique Sirio Tejero Cantero
  end

  def shipping_addresses
    # Promotes address2 to address1 when address1 is absent.
    [
      @order_hash['ShippingAddress']['AddressLine1'],
      @order_hash['ShippingAddress']['AddressLine2'],
      @order_hash['ShippingAddress']['AddressLine3']
    ].
    compact.
    reject { |address| address.empty? }
  end

  def order_phone_number
    phone_number = @order_hash['ShippingAddress']['Phone'].to_s.strip
    if phone_number.empty?
      return '000-000-0000'
    end
    phone_number
  end

  def roll_up_item_values
    @line_items.each do |item|
      @shipping_total     += item.shipping_price
      @shipping_discount  += item.shipping_discount
      @promotion_discount += item.promotion_discount
      @amazon_tax         += item.item_tax
      @gift_wrap          += item.gift_wrap
      @gift_wrap_tax      += item.gift_wrap_tax
      @items_total        += item.total_price
    end
  end

  def assemble_totals_hash
    { item: @items_total,
      adjustment: @promotion_discount + @shipping_discount + @gift_wrap + @amazon_tax + @gift_wrap_tax,
      tax: @amazon_tax + @gift_wrap_tax,
      shipping: @shipping_total,
      order:  @order_total,
      payment: @order_total }
  end

  def assemble_adjustments_hash
    [
      { name: 'Shipping Discount',  value: @shipping_discount },
      { name: 'Promotion Discount', value: @promotion_discount },
      { name: 'Amazon Tax',         value: @amazon_tax },
      { name: 'Gift Wrap Price',    value: @gift_wrap },
      { name: 'Gift Wrap Tax',      value: @gift_wrap_tax }
   ]
  end

  def assemble_shipment_hash(line_items)
    [{ cost: @shipping_total,
       status: @status,
      #  shipping_method: order_shipping_method,
       items: line_items,
       stock_location: '',
       tracking: '',
       number: '' }]
  end

  def order_shipping_method
    amazon_shipping_method = @order_hash['ShipmentServiceLevelCategory']
    # amazon_shipping_method_lookup.each do |shipping_method, value|
    #   return value if shipping_method.downcase == amazon_shipping_method.downcase
    # end
    amazon_shipping_method
  end

  # def amazon_shipping_method_lookup
  #   @config['amazon.shipping_method_lookup'].to_a.first.to_h
  # end

  def order_full_state
    state  = @order_hash['ShippingAddress']['StateOrRegion'].to_s
    if @order_hash['ShippingAddress']['CountryCode'].to_s.upcase != 'US'
      return state
    end
    convert_us_state_name(state)
  end

  def convert_us_state_name(state_abbr)
    exceptions = { 'AA'   => 'U.S. Armed Forces – Americas',
                   'AE'   => 'U.S. Armed Forces – Europe',
                   'AP'   => 'U.S. Armed Forces – Pacific',
                   'D.C.' => 'District Of Columbia' }

    exceptions[state_abbr] || ModelUN.convert_state_abbr(state_abbr)
  end
end
