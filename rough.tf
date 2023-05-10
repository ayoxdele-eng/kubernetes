resource "tls_private_key" "createkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "aws_key_pair" "generated_key" {
  key_name   = "terraform-key"
  public_key = tls_private_key.createkey.public_key_openssh
}

resource "null_resource" "savekey" {
  depends_on = [
    tls_private_key.createkey,
  ]
  provisioner "local-exec" {
    command = "echo  '${tls_private_key.createkey.private_key_pem}' > wordpress_key.pem"
  }
}