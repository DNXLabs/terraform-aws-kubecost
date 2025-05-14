mock_provider "aws" {
  override_data {
    target = data.aws_region.current
    values = {
      name = "ap-southeast-2"
    }
  }
}

mock_provider "aws" {
  alias = "us-east-1"
  override_data {
    target = data.aws_region.current
    values = {
      name = "us-east-1"
    }
  }
}

run "valid_all_vars" {
  command = plan
  variables {
    name = "cur_test"
    environment = "test"
  }
}

