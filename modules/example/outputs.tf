# Output variable definitions

output "name" {
  description = "Virtual machine name"
  value       = azurerm_virtual_machine.example.name
}

output "id"{
	description = "Virtual machine name"
  value       = azurerm_virtual_machine.example.id
}