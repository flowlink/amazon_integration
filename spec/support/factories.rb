module Factories
  class << self

    def customers
      [Customer.new(customer_responses[0])]
    end

    def orders(client, redis)
      order1 = Order.new(order_responses[0], client, redis)
      order2 = Order.new(order_responses[1], client, redis)
      order1.line_items << LineItem.new(item_responses[0])
      order2.line_items << LineItem.new(item_responses[1])
      [order1, order2]
    end

    def customer_responses
      [
        {
          'CustomerId' => 'CID',
          'PrimaryContactInfo' => {
            'Email' => 'spree@example.com',
            'FullName' => 'First Middle Last'
          },
          'ShippingAddressList' => {
            'ShippingAddress' => {
              'IsDefaultAddress' => 'true',
              'FullName' => 'First Middle Last',
              'AddressLine1' => '1 address line',
              'AddressLine2' => '2 address lines',
              'PostalCode' => 'zip',
              'City' => 'city',
              'CountryCode' => 'US',
              'StateOrRegion' => 'VT',
              'Phone' => '555-555-5555'
            }
          },
          'AssociatedMarketplaces' => {
            'MarketplaceDomain' => {
              'DomainName' => 'www.example.com'
            }
          }
        },
      ]
    end

    def order_responses
      [{ "ShipmentServiceLevelCategory"=>"Standard",
        "OrderTotal"=>{"Amount"=>"8.79", "CurrencyCode"=>"USD"},
        "ShipServiceLevel"=>"Std Cont US Street Addr",
        "MarketplaceID"=>"ATVPDKIKX0DER",
        "ShippingAddress"=>
          {"Phone"=>"2409971905",
           "PostalCode"=>"20837-3004",
           "Name"=>"Wesley Scott Ketchum",
           "CountryCode"=>"US",
           "StateOrRegion"=>"MD",
           "AddressLine1"=>"19944 SPURRIER AVE",
           "AddressLine2"=>"APTO 1",
           "City"=>"POOLESVILLE"},
           "SalesChannel"=>"Amazon.com",
        "ShippedByAmazonTFM"=>"false",
        "OrderType"=>"StandardOrder",
        "BuyerEmail"=>"knsrqr1h8bkp9yh@marketplace.amazon.com",
        "FulfillmentChannel"=>"MFN",
        "OrderStatus"=>"Shipped",
        "BuyerName"=>"wes ketchum",
        "LastUpdateDate"=>"2013-06-17T21:41:33Z",
        "PurchaseDate"=>"2013-06-17T20:12:54Z",
        "NumberOfItemsUnshipped"=>"0",
        "NumberOfItemsShipped"=>"5",
        "AmazonOrderID"=>"111-6494089-5358640",
        "PaymentMethod"=>"Other" },
        {"ShipmentServiceLevelCategory"=>"Standard",
         "OrderTotal"=>{"Amount"=>"16.19", "CurrencyCode"=>"USD"},
         "ShipServiceLevel"=>"Std Cont US Street Addr",
         "MarketplaceID"=>"ATVPDKIKX0DER",
         "ShippingAddress"=>
          {"PostalCode"=>"20837-3004",
           "Name"=>"Wesley Scott Ketchum",
           "CountryCode"=>"US",
           "StateOrRegion"=>"MD",
           "AddressLine2"=>"19944 SPURRIER AVE",
           "City"=>"POOLESVILLE"},
         "SalesChannel"=>"Amazon.com",
         "ShippedByAmazonTFM"=>"false",
         "OrderType"=>"StandardOrder",
         "BuyerEmail"=>"knsrqr1h8bkp9yh@marketplace.amazon.com",
         "FulfillmentChannel"=>"MFN",
         "OrderStatus"=>"Unshipped",
         "BuyerName"=>"wes ketchum",
         "LastUpdateDate"=>"2013-06-19T17:45:49Z",
         "PurchaseDate"=>"2013-06-19T17:15:29Z",
         "NumberOfItemsUnshipped"=>"2",
         "NumberOfItemsShipped"=>"0",
         "AmazonOrderID"=>"111-2374817-1293015",
         "PaymentMethod"=>"Other"} ]
    end

    def item_responses
     [{ "OrderItemID"=>"58145946945682",
         "GiftWrapPrice"=>{"Amount"=>"0.00", "CurrencyCode"=>"USD"},
         "QuantityOrdered"=>"3",
         "Gift_wrap_tax"=>{"Amount"=>"0.00", "CurrencyCode"=>"USD"},
         "SellerSKU"=>"G9-LTWP-D1LD",
         "Title"=>"Zak Designs Ella Individual Bowls, Orange, Set of 6",
         "ShippingTax"=>{"Amount"=>"0.00", "CurrencyCode"=>"USD"},
         "ShippingPrice"=>{"Amount"=>"5.69", "CurrencyCode"=>"USD"},
         "ItemTax"=>{"Amount"=>"0.00", "CurrencyCode"=>"USD"},
         "ItemPrice"=>{"Amount"=>"9.00", "CurrencyCode"=>"USD"},
         "PromotionDiscount"=>{"Amount"=>"0.00", "CurrencyCode"=>"USD"},
         "asin"=>"B005PY90JS",
         "ConditionId"=>"Used",
         "QuantityShipped"=>"3",
         "ConditionSubtypeId"=>"Mint",
         "ShippingDiscount"=>{"Amount"=>"0.00", "CurrencyCode"=>"USD"}},
       {"OrderItemId"=>"01029183238402",
       "GiftWrapPrice"=>{"Amount"=>"0.00", "CurrencyCode"=>"USD"},
       "QuantityOrdered"=>"1",
       "GiftWrapTax"=>{"Amount"=>"0.00", "CurrencyCode"=>"USD"},
       "SellerSKU"=>"SV-Q5JI-31JT",
       "Title"=>
        "10 Strawberry Street Catering Set 10-1/2-Inch Dinner Plate, Set of 12",
       "ShippingTax"=>{"Amount"=>"0.00", "CurrencyCode"=>"USD"},
       "ShippingPrice"=>{"Amount"=>"13.75", "CurrencyCode"=>"USD"},
       "ItemTax"=>{"Amount"=>"0.00", "CurrencyCode"=>"USD"},
       "ItemPrice"=>{"Amount"=>"9.00", "CurrencyCode"=>"USD"},
       "PromotionDiscount"=>{"amount"=>"0.00", "currency_code"=>"USD"},
       "asin"=>"B002LAAFYS",
       "ConditionId"=>"Refurbished",
       "QuantityShipped"=>"0",
       "ConditionSubtypeId"=>"Refurbished",
       "ShippingDiscount"=>{"Amount"=>"0.00", "CurrencyCode"=>"USD"}}]
    end

    def shipment
      {
          "number" => "H03606064322",
          "order_id" => "103-6652650-4045858",
          "email" => "spree@example.com",
          "cost" => 0.0,
          "status" => "ready",
          "stock_location" => nil,
          "shipping_method" => "Economy (5-10 Business Days - $0.00)",
          "tracking" => "915293072790129",
          "updated_at" => nil,
          "shipped_at" => nil,
          "shipping_address"=> {
          "firstname"=> "Brian",
          "lastname"=> "Quinn",
          "address1"=> "2 Wisconsin Cir.",
          "address2"=> "",
          "zipcode"=> "20815",
          "city"=> "Chevy Chase",
          "state"=> "Maryland",
          "country"=> "US",
          "phone"=> "555-123-123"
          },
          "items" => [
            {
              "name" => "test",
              "sku" => "27368845791002",
              "external_ref" => "",
              "quantity" => 1,
              "price" => 1.25,
              "variant_id" => 2,
              "options" => {
              }
            }
          ]
      }
    end

    def line_item
      {
        "sku" => "2Y-0BPV-TWZY",
        "quantity" => 20
      }
    end
  end
end
