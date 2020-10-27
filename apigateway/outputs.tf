# Output variable definitions

output "frontend_net" {
  description = "Virtual machine name"
  value       = azurerm_subnet.frontend


output "backend_net" {
  description = "Virtual machine name"
  value       = azurerm_subnet.backend
}

output "public_ip" {
  description = "Virtual machine name"
  value       = azurerm_public_ip.example
}