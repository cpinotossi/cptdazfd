locals {
  my_public_ip = data.http.my_ip.response_body
}
