module Feeds
  class OrderFulfillment
    attr_reader :feed_type

    def initialize(shipment, config)
      @merchant_id      = config['merchant_id']
      @shipment         = shipment
      @use_carrier_code = config['send_shipping_carrier_code']
    end

    def to_xml
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.AmazonEnvelope {
          xml.Header {
            xml.DocumentVersion 1.01
            xml.MerchantIdentifier @merchant_id
          }
          xml.MessageType 'OrderFulfillment'
          xml.PurgeAndReplace 'false'
          xml.Message {
            xml.MessageID 1
            xml.OperationType 'Update'
            xml.OrderFulfillment {
              xml.AmazonOrderID @shipment['order_id']
              xml.MerchantFulfillmentID @shipment['order_id'].gsub(/\D/, '')
              xml.FulfillmentDate Time.now.strftime('%Y-%m-%dT%H:%M:%S')
              xml.FulfillmentData  {
                # If user opts in their shipping carrier should match Amazons Carrier Codes
                if @use_carrier_code == '1'
                  xml.CarrierCode @shipment['shipping_carrier']
                else
                  xml.CarrierName @shipment['shipping_carrier']
                end
                xml.ShippingMethod @shipment['shipping_method']
                xml.ShipperTrackingNumber @shipment['tracking']
              }

            }
          }
        }
      end

      builder.to_xml
    end

    def feed_type
      '_POST_ORDER_FULFILLMENT_DATA_'
    end
  end
end
