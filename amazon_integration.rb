require "sinatra"
require "endpoint_base"
require 'mws-connect'

require_all 'lib'

class AmazonIntegration < EndpointBase::Sinatra::Base
  set :logging, true

  # NOTE: Can only be used in development this will break production if left in uncommented.
  # configure :development do
  #   enable :logging, :dump_errors, :raise_errors
  #   log = File.new("tmp/sinatra.log", "a")
  #   STDOUT.reopen(log)
  #   STDERR.reopen(log)
  # end

  before do
    @mws = Mws.connect(
      merchant: @config['merchant_id'],
      access:   @config['aws_access_key_id'],
      secret:   @config['secret_key']
    )
  end

  post '/add_product' do
    begin
      code, response = submit_product_feed
    rescue => e
      log_exception(e)
      code, response = handle_error(e)
    end
    result code, response
  end

  post '/get_customers' do
    begin
      client = MWS::CustomerInformation.new(
        aws_access_key_id:     @config['aws_access_key_id'],
        aws_secret_access_key: @config['secret_key'],
        marketplace_id:        @config['marketplace_id'],
        merchant_id:           @config['merchant_id']
      )
      amazon_response = client.list_customers(last_updated_after: @config['amazon_customers_last_polling_datetime']).parse

      collection = amazon_response['Customers']['Customer'].is_a?(Array) ? amazon_response['Customers']['Customer'] : [amazon_response['Customers']['Customer']]
      customers = collection.map { |customer| Customer.new(customer) }

      unless customers.empty?
        customers.each { |customer| add_object :customer, customer.to_message }
        add_parameter 'amazon_customers_last_polling_datetime', customers.last.last_update_date
      end

      code     = 200
      response = "Successfully received #{customers.size} customer(s) from Amazon MWS."
    rescue => e
      code, response = handle_error(e)
    end

    result code, response
  end

  post '/get_orders' do
    begin
      # TODO remove pending
      statuses = %w(PartiallyShipped Unshipped)
      client = MWS::Orders.new(
        aws_access_key_id:     @config['aws_access_key_id'],
        aws_secret_access_key: @config['secret_key'],
        marketplace_id:        @config['marketplace_id'],
        merchant_id:           @config['merchant_id']
      )
      amazon_response = client.list_orders(last_updated_after: @config['amazon_orders_last_polling_datetime'], order_status: statuses).parse

      collection = amazon_response['Orders']['Order'].is_a?(Array) ? amazon_response['Orders']['Order'] : [amazon_response['Orders']['Order']]
      orders = collection.map { |order| Order.new(order, client) }

      unless orders.empty?
        orders.each { |order| add_object :order, order.to_message }
        add_parameter 'amazon_orders_last_polling_datetime', orders.last.last_update_date
      end

      code     = 200
      response = "Successfully received #{orders.size} order(s) from Amazon MWS."
    rescue => e
      code, response = handle_error(e)
    end

    result code, response
  end

  post '/set_inventory' do
    begin
      inventory_feed = @mws.feeds.inventory.update(
        Mws::Inventory(@payload['inventory']['product_id'],
          quantity: @payload['inventory']['quantity'],
          fulfillment_type: :mfn
        )
      )
      response = "Submitted SKU #{@payload['inventory']['product_id']} MWS Inventory Feed ID: #{inventory_feed.id}"
      code = 200
    rescue => e
      code, response = handle_error(e)
    end

    result code, response
  end

  post '/update_product' do
    begin
      code, response = submit_product_feed
    rescue => e
      log_exception(e)
      code, response = handle_error(e)
    end
    result code, response
  end

  post '/update_shipment' do
    begin
      raise 'TODO'
      code = 200
    rescue => e
      code, response = handle_error(e)
    end

    result code, response
  end

  # post '/feed_status' do
  #   begin
  #     raise 'TODO?'
  #     code = 200
  #   rescue => e
  #     code, response = handle_error(e)
  #   end
  #
  #   result code, response
  # end

  private

  def submit_product_feed
    mws = Mws.connect(
      merchant: @config['merchant_id'],
      access: @config['aws_access_key_id'],
      secret: @config['secret_key']
    )

    title = @payload['product']['name']

    product = Mws::Product(@payload['product']['sku']) {
      # upc '123435566654'
      # tax_code 'GEN_TAX_CODE'
      # name 'Some Product 123'
      # brand 'Some Brand'
      # msrp 19.99, 'USD'
      # manufacturer 'Some Manufacturer'
      upc '847651325546'
      tax_code 'A_GEN_TAX'
      # name "Spree T-Shirt"
      name title

      # name "Rocketfish 6' In-Wall HDMI Cable"
      # brand "Rocketfish"
      # description "This 6' HDMI cable supports signals up to 1080p and most screen refresh rates to ensure stunning image clarity with reduced motion blur in fast-action scenes."
      # bullet_point 'Compatible with HDMI components'
      # msrp 495.99, :usd
      category :ce
      details {
        cable_or_adapter {
          cable_length as_distance 6, :feet
        }
      }
    }

    product_feed = mws.feeds.products.add(product)
    # workflow.register product_feed.id do
    #   price_feed = mws.feeds.prices.add(
    #     Mws::PriceListing('2634897', 495.99)#.on_sale(29.99, Time.now, 3.months.from_now)
    #   )
    #   image_feed = mws.feeds.images.add(
    #     Mws::ImageListing('2634897', 'http://images.bestbuy.com/BestBuy_US/images/products/2634/2634897_sa.jpg', 'Main'),
    #     Mws::ImageListing('2634897', 'http://images.bestbuy.com/BestBuy_US/images/products/2634/2634897cv1a.jpg', 'PT1')
    #   )
    #   shipping_feed = mws.feeds.shipping.add(
    #     Mws::Shipping('2634897') {
    #       restricted :alaska_hawaii, :standard, :po_box
    #       adjust 4.99, :usd, :continental_us, :standard
    #       replace 11.99, :usd, :continental_us, :expedited, :street
    #     }
    #   )
    #   workflow.register price_feed.id, image_feed.id, shipping_feed.id do
    #     inventory_feed = mws.feeds.inventory.add(
    #       Mws::Inventory('2634897', quantity: 10, fulfillment_type: :mfn)
    #     )
    #     workflow.register inventory_feed.id do
    #       puts 'The workflow is complete!'
    #     end
    #     inventory_feed.id
    #   end
    #   [ price_feed.id, image_feed.id, shipping_feed.id ]
    #  end
    #   product_feed.id
    # end
    #
    # workflow.proceed

    [200, "Submitted SKU #{@payload['product']['sku']} with MWS Feed ID: #{product_feed.id}"]
  end

  def handle_error(e)
    response = [e.message, e.backtrace.to_a].flatten.join('\n\t')
    [500, response]
  end

end
