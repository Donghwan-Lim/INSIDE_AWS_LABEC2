output "ami-id" {
  value = data.aws_ami.recent_amazon_linux.id
}

output "priv_key" {
  value = tls_private_key.ssh-priv-key.private_key_pem
  sensitive = true
}