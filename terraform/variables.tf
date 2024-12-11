# SSH Key Name
variable "key_name" {
  description = "Nom de la clé SSH"
  type        = string
}

# Path to the private SSH key
variable "private_key_path" {
  description = "Chemin vers la clé privée SSH"
  type        = string
}
