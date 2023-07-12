output "ami-id" {
  value = data.aws_ami.recent_amazon_linux.id
}
/* key pair managed by AWS Console
output "priv_key" {
  value = tls_private_key.ssh-priv-key.private_key_pem
  sensitive = true
}

output "public_key" {
  value = tls_private_key.ssh-priv-key.public_key_openssh
}
*/