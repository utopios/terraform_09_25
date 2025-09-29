variable "set_of_names" {
  description = "A set of names"
  type        = set(string)
  default     = ["Alice", "Bob", "Charlie"]
}
resource "null_resource" "example" {
  for_each = var.set_of_names
  #name = each.value
}

