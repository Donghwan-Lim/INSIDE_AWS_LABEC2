output "ami-id" {
  value = data.aws_ami.recent_amazon_linux.id
}

output "vm1_public_up" {
  value = aws_instance.public_vm_01.public_ip
}

output "vm2_public_up" {
  value = aws_instance.public_vm_02.public_ip
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