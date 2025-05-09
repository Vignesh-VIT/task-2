resource "azurerm_route_table" "private_route_table" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "private_route_association" {
  subnet_id      = var.subnet_id
  route_table_id = azurerm_route_table.private_route_table.id
}
