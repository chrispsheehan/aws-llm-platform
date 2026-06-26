output "instance_id" {
  value = aws_instance.this.id
}

output "public_ip" {
  value = aws_eip.this.public_ip
}

output "web_url" {
  value = "http://${aws_eip.this.public_ip}:3000"
}
