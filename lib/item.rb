class Item
  attr_accessor :shipping_price    , :item_tax   , :promotion_discount ,
                :shipping_discount , :gift_wrap  , :gift_wrap_tax      ,
                :total_price       , :unit_price

  def initialize(item_hash)
    @name               = item_hash['title']
    @quantity           = item_hash['quantity_ordered'].to_i
    @quantity_shipped   = item_hash['quantity_shipped']
    @sku                = item_hash['seller_sku']
    # Optional attributes
    @item_tax           = item_hash.fetch('item_tax',           {})['amount'].to_f
    @promotion_discount = item_hash.fetch('promotion_discount', {})['amount'].to_f
    @total_price        = item_hash.fetch('item_price',         {})['amount'].to_f
    @unit_price         = unit_price
    @shipping_price     = item_hash.fetch('shipping_price',     {})['amount'].to_f
    @shipping_discount  = item_hash.fetch('shipping_discount',  {})['amount'].to_f
    @gift_wrap          = item_hash.fetch('gift_wrap_price',    {})['amount'].to_f
    @gift_wrap_tax      = item_hash.fetch('gift_wrap_tax',      {})['amount'].to_f
  end

  def to_h
    { name:          @name,
      price:         @unit_price,
      sku:           @sku,
      quantity:      @quantity,
      variant_id:    nil,
      external_ref:  nil,
      options:       {} }
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
