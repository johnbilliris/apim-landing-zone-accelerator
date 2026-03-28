variable "apim_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "ip_address" {
  type = string
}

resource "azurerm_private_dns_a_record" "gateway_record" {
  name                = "${var.apim_name}.azure-api.net"
  zone_name           = "${var.apim_name}.azure-api.net"
  resource_group_name = var.resource_group_name
  ttl                 = 36000
  records             = [var.ip_address]
}

resource "azurerm_private_dns_a_record" "developer_record" {
  name                = "${var.apim_name}.developer.azure-api.net"
  zone_name           = "${var.apim_name}.azure-api.net"
  resource_group_name = var.resource_group_name
  ttl                 = 36000
  records             = [var.ip_address]
}