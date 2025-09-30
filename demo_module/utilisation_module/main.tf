module "simple_module" {
  source = "../demo_creation_module"
  v1 = "test utilisation module par notre projet"
}

output "result_from_module" {
  value = module.simple_module.result_module_v1
}