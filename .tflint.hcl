plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Variables used in module call blocks are not tracked when call_module_type = "none"
rule "terraform_unused_declarations" {
  enabled = false
}
