mock_provider "aws" {}

mock_provider "aws" {
  alias = "us-east-1"
}

run "valid_required_vars" {
  command = plan
  variables {
    name = "cur_test"
  }
}

