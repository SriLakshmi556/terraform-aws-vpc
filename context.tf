module "label" {
  source                 = "github.com/obytes/terraform-aws-tag.git?ref=v1.0.5"
  environment            = var.environment
  project_name           = var.project_name
  region                 = var.region
  delimiter              = var.delimiter
  attributes             = var.attributes
  enabled                = var.enabled
  prefix_order           = var.prefix_order
  regex_substitute_chars = var.regex_substitute_chars
  prefix_length_limit    = var.prefix_length_limit
  tag_key_case           = var.tag_key_case
  tag_value_case         = var.tag_value_case

  context = var.context
}

variable "context" {
  type = any
  default = {
    enabled                = true
    environment            = null
    project_name           = null
    region                 = null
    name                   = null
    delimiter              = null
    attributes             = null
    tags                   = {}
    additional_tags        = {}
    prefix_order           = ["environment", "project_name", "region", "name", "attributes"]
    prefix_length_limit    = 0
    regex_substitute_chars = null
    tag_key_case           = "title"
    tag_value_case         = "lower"
    random_string          = null
    attributes             = []
  }

  validation {
    condition     = lookup(var.context, "tag_key_case", null) == null ? true : contains(["lower", "upper", "title"], var.context["tag_key_case"])
    error_message = "Valid values are only upper, lower and title."
  }

  validation {
    condition     = lookup(var.context, "tag_value_case", null) == null ? true : contains(["lower", "upper", "title"], var.context["tag_value_case"])
    error_message = "Valid values are only upper, lower and title."
  }
  validation {
    condition     = lookup(var.context, "region", null) == null ? true : contains(["us-east-1", "us-east-2", "us-west-1", "us-west-2", "af-south-1", "ap-east-1", "ap-south-1", "ap-northeast-3", "ap-northeast-2", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1", "ca-central-1", "eu-central-1", "eu-west-1", "eu-west-2", "eu-south-1", "eu-west-3", "eu-north-1", "me-south-1", "sa-east-1"], var.context.region)
    error_message = "Only a valid AWS region names are expected here such as af-south-1."
  }
}

variable "enabled" {
  type        = string
  default     = null
  description = "A boolean to enable or disable tagging/labeling module"
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Environment name such as us-east-1, ap-west-1, eu-central-1"

  validation {
    condition     = var.region == null ? true : contains(["us-east-1", "us-east-2", "us-west-1", "us-west-2", "af-south-1", "ap-east-1", "ap-south-1", "ap-northeast-3", "ap-northeast-2", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1", "ca-central-1", "eu-central-1", "eu-west-1", "eu-west-2", "eu-south-1", "eu-west-3", "eu-north-1", "me-south-1", "sa-east-1"], var.region)
    error_message = "Only a valid AWS region names are expected here such as af-south-1."
  }
}

variable "project_name" {
  type        = string
  default     = null
  description = "The project name or organization name, could be fullName or abbreviation such as `ex`"
}

variable "environment" {
  type        = string
  default     = null
  description = "Environment, the environment name such as 'stg', 'prd', 'dev'"
}

variable "name" {
  type        = string
  default     = null
  description = "The name of the service/solution such as vpc, ec2"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags, Tags to be generated by this module which can be access by module.<name>.tags e.g. map('CostCenter', 'Production')"
}

variable "additional_tags" {
  type        = map(string)
  default     = {}
  description = "Additional Tags, tags which can be accessed by module.<name>.tags_as_list not added to <module>.<name>.<tags>"
}

variable "delimiter" {
  type    = string
  default = null

  description = <<-EOL
    Delimiter to be used between `project_name`, `environment`, `region` and, `name`.
    Defaults to `-` (hyphen). Set to `""` to use no delimiter at all.
  EOL
}

variable "regex_substitute_chars" {
  type        = string
  default     = null
  description = <<-EOL
  a regex to replace empty chars in `project_name`, `environment`, `region` and, `name`
  defaults to `"\[a-zA-Z0-9]\"`, replacing any chars other than chars and digits
  EOL
}

variable "tag_key_case" {
  type        = string
  default     = null
  description = <<-EOL
  The letter case of output tag keys
  Possible values are `lower', `upper` and `title`
  defaults to `title`
  EOL
  validation {
    condition     = var.tag_key_case == null ? true : contains(["lower", "upper", "title"], var.tag_key_case)
    error_message = "Valid values are only upper, lower and title."
  }
}

variable "tag_value_case" {
  type        = string
  default     = null
  description = <<-EOL
  The letter case of output tag values
  Possible values are `lower', `upper` and `title`
  defaults to `lower`
  EOL
  validation {
    condition     = var.tag_value_case == null ? true : contains(["lower", "upper", "title"], var.tag_value_case)
    error_message = "Valid values are only upper, lower and title."
  }
}

variable "prefix_order" {
  type        = list(string)
  default     = null
  description = <<-EOL
  The order of the Name tag
  Defaults to, `["environment", "project_name", "region", "name"]`
  at least one should be provided
  EOL
}

variable "prefix_length_limit" {
  type        = number
  default     = null
  description = <<-EOL
  The minimum number of chars required for the id/Name desired (minimum =7)
  Set it to `0` for unlimited number of chars, `full_id`
  EOL

  validation {
    condition     = var.prefix_length_limit == null ? true : var.prefix_length_limit >= 7 || var.prefix_length_limit == 0
    error_message = "Error, The minimum length should be 7 or set it to 0 for unlimited length."
  }
}

variable "attributes" {
  type        = list(string)
  default     = null
  description = "A list of attributes e.g. `private`, `shared`, `cost_center`"
}

variable "random_string" {
  type        = string
  default     = null
  description = <<-EOL
  A Random string, that will be appended to `id` in case of using `prefix_length_limit`
  Using the default value which is `null`, the string will be created using the `random` terraform provider
  EOL
}
