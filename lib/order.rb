class Order
  attr_accessor :amazon_tax,
                  :fulfillment_channel,
                  :gift_wrap,
                  :gift_wrap_tax,
                  :items_total,
                  :last_update_date,
                  :line_items,
                  :number,
                  :order_hash,
                  :promotion_discount,
                  :shipping_address,
                  :shipping_discount,
                  :shipping_total,
                  :status

  def initialize(order_hash, client, redis)
    @client              = client
    @redis               = redis
    @line_items          = []
    @order_hash          = order_hash
    @number              = order_hash['AmazonOrderId']
    @order_total         = order_hash['OrderTotal']['Amount'].to_f
    @last_update_date    = order_hash['LastUpdateDate']
    @status              = order_hash['OrderStatus']
    @shipping_address    = assemble_address
    @shipping_total      = 0.00
    @shipping_discount   = 0.00
    @promotion_discount  = 0.00
    @amazon_tax          = 0.00
    @gift_wrap           = 0.00
    @gift_wrap_tax       = 0.00
    @items_total         = 0.00
    @fulfillment_channel = order_hash['FulfillmentChannel']
  end

  def fulfilled_by_amazon?
    order_hash['FulfillmentChannel'] != 'MFN'
  end

  def to_message
    roll_up_item_values
    items_hash       = assemble_line_items
    adjustments_hash = assemble_adjustments_hash

    {
      id: @number,
      number: @number,
      channel: @order_hash['SalesChannel'],
      fulfillment_channel: @fulfillment_channel,
      currency: @order_hash['OrderTotal']['CurrencyCode'],
      status: @order_hash['OrderStatus'],
      placed_on: @order_hash['PurchaseDate'],
      updated_at: @order_hash['LastUpdateDate'],
      email: @order_hash['BuyerEmail'],
      totals: assemble_totals_hash,
      adjustments: adjustments_hash,
      line_items: items_hash,
      payments: [{
        amount: @order_total,
        payment_method: 'Amazon',
        status: 'complete'
      }],
      shipping_address: @shipping_address,
      # TODO: Should we even return the billing address?  We are only given a shipping address.
      billing_address: @shipping_address,
      amazon_shipping_method: order_shipping_method
    }
  end

  def to_shipment
    {
      id: @number,
      number: @number,
      order_id: @number,
      channel: @order_hash['SalesChannel'],
      cost: @shipping_total,
      totals: assemble_totals_hash,
      status: @status,
      billing_address: @shipping_address,
      shipping_address: @shipping_address,
      shipping_method: order_shipping_method,
      items: @line_items,
      stock_location: '',
      tracking: '',
      amazon_shipping_method: order_shipping_method,
      fulfillment_channel: @fulfillment_channel
    }
  end

  private

  def assemble_line_items
    item_response = @client.list_order_items(@number).parse
    collection = item_response['OrderItems']['OrderItem'].is_a?(Array) ? item_response['OrderItems']['OrderItem'] : [item_response['OrderItems']['OrderItem']]
    @line_items = collection.map { |item| LineItem.new(item).to_h }
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
    firstname, lastname = Customer.names @order_hash['ShippingAddress']['Name']
    address1,  address2 = shipping_addresses

    {
      firstname:  firstname,
      lastname:   lastname,
      address1:   address1.to_s,
      address2:   address2.to_s,
      city:       @order_hash['ShippingAddress']['City'],
      zipcode:    @order_hash['ShippingAddress']['PostalCode'],
      phone:      order_phone_number,
      country:    @order_hash['ShippingAddress']['CountryCode'],
      state:      order_full_state
    }
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
    {
      item: @items_total,
      adjustment: @promotion_discount + @shipping_discount + @gift_wrap + @amazon_tax + @gift_wrap_tax,
      tax: @amazon_tax + @gift_wrap_tax,
      shipping: @shipping_total,
      order:  @order_total,
      payment: @order_total
    }
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
    # Manual exceptions can be done here.
    exceptions = { 'AA'   => 'U.S. Armed Forces – Americas',
                   'AE'   => 'U.S. Armed Forces – Europe',
                   'AP'   => 'U.S. Armed Forces – Pacific',
                   'D.C.' => 'District Of Columbia' }

    # Amazon allows users to input whatever state they want so we need to sanity check here.
    # We will look up the state by postal code from Google API and convert to full state name.
    # Then we cache in redis to prevent API throttling.
    # See: https://sellercentral.amazon.com/forums/message.jspa?messageID=2483353
    state_by_postal_code = @redis.get("zip-#{@order_hash['ShippingAddress']['PostalCode']}")
    if state_by_postal_code.nil?
      begin
        Geokit::Geocoders::GoogleGeocoder.api_key = ENV['GOOGLE_GEOCODE_API_KEY']
        result = Geokit::Geocoders::GoogleGeocoder.geocode(@order_hash['ShippingAddress']['PostalCode'])
        state_by_postal_code = if result.is_us?
          ModelUN.convert_state_abbr(result.state).split.map(&:capitalize).join(' ')
        else
          result.state
        end
        @redis.set("zip-#{@order_hash['ShippingAddress']['PostalCode']}", state_by_postal_code) unless state_by_postal_code.nil?
      rescue
        state_by_postal_code ||= ModelUN.convert_state_abbr(state_abbr.upcase).split.map(&:capitalize).join(' ')
      end
    end

    exceptions[state_abbr.upcase] || state_by_postal_code
  end

end
