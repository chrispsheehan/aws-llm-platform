variable "scan_on_push" {
  type    = bool
  default = true
}

variable "force_delete" {
  type    = bool
  default = false
}

variable "image_expiration_days" {
  type    = number
  default = 0
}

variable "repository_name" {
  type = string
}

variable "images" {
  type = map(object({
    source_image = string
    source_tag   = string
    target_tag   = string
  }))
}
