variable "ssh_public_key" {
  description = "Chave pública SSH usada no key pair da EC2 (injetada via TF_VAR_ssh_public_key)"
  type        = string
  sensitive   = true
}
