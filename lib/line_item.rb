class LineItem

  attr_accessor :shipping_price,
                  :item_tax,
                  :promotion_discount,
                  :shipping_discount,
                  :gift_wrap,
                  :gift_wrap_tax,
                  :total_price,
                  :unit_price

  def initialize(item_hash)
    @asin               = item_hash['ASIN']
    @name               = item_hash['Title']
    @quantity           = item_hash['QuantityOrdered'].to_i
    @quantity_shipped   = item_hash['QuantityShipped']
    @sku                = item_hash['SellerSKU']
    # Optional attributes
    @item_tax           = item_hash.fetch('ItemTax',           {})['Amount'].to_f
    @promotion_discount = item_hash.fetch('PromotionDiscount', {})['Amount'].to_f
    @total_price        = item_hash.fetch('ItemPrice',         {})['Amount'].to_f
    @unit_price         = unit_price.to_f
    @shipping_price     = item_hash.fetch('ShippingPrice',     {})['Amount'].to_f
    @shipping_discount  = item_hash.fetch('ShippingDiscount',  {})['Amount'].to_f
    @gift_wrap          = item_hash.fetch('GiftWrapPrice',     {})['Amount'].to_f
    @gift_wrap_tax      = item_hash.fetch('GiftWrapTax',       {})['Amount'].to_f
  end

  def to_h
    {
      name:       @name,
      price:      @unit_price,
      product_id: @sku,
      quantity:   @quantity,
      asin:       @asin,
      options:    {}
    }
  end

  private

  def unit_price
    if @total_price > 0.0 && @quantity > 0
      @total_price / @quantity
    else
      @total_price
    end
  end

end
