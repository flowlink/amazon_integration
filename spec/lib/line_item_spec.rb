require 'spec_helper'

describe LineItem do

  let(:order) { Factories.orders(double(MWS)).first }

  subject { order.line_items.first }

  it 'should convert into a hash' do
    item_hash = subject.to_h
    item_hash.class.should eq Hash
    item_hash[:sku].should eq "G9-LTWP-D1LD"
  end

  it '#unit_price' do
    expect(subject.send(:unit_price)).to eq 3.0
  end
end
