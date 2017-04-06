# Amazon Integration

## Overview

This is a fully hosted and supported integration for use with the [Wombat](http://wombat.co) product.

To debug feeds you can view results with the scratchpad:
[https://mws.amazonservices.com/scratchpad/index.html](https://mws.amazonservices.com/scratchpad/index.html)

## Connection Parameters

The following parameters must be setup within [FlowLink](http://flowlink.io/):

| Name | Value |
| :----| :-----|
| merchant_id | Merchant ID (required) |
| marketplace_id | Marketplace ID (required) |
| access_key | Access Key (required) |
| secret_key | Secret Key (required) |

## Webhooks

The following webhooks are implemented:

| Name | Description |
| :----| :-----------|
| /add_product | Adds existing products within Amazon's catalog to your account |
| /get_customers | Polls Amazon Webstore for Customers. NOTE: Only returns customer information for Webstores with Seller-Branded Checkout. |
| /get_orders | Polls Amazon for Orders |
| /set_inventory | Updates Inventory Quantity for a SKU |
| /update_product | Updates the corresponding Amazon product |
| /update_shipment | Updates the corresponding Amazon order with shipping info |

# About FlowLink

[FlowLink](http://flowlink.io/) allows you to connect to your own custom integrations.
Feel free to modify the source code and host your own version of the integration
or better yet, help to make the official integration better by submitting a pull request!

This integration is 100% open source an licensed under the terms of the New BSD License.

![FlowLink Logo](http://flowlink.io/wp-content/uploads/logo-1.png)
