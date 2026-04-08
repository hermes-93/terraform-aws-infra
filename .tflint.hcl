config {
  # Don't resolve local module calls — each module is linted separately
  call_module_type = "none"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
