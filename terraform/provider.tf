provider "aws" {
  region = "us-east-1"

  # NOTE For limited access credentials you can either use:
  # profile = "some-profile" # The profile as configured in .aws/config
  # assume_role { ... }      # The raw role to use.
  # NOTE In case you need MFA support, there's a separate aws-vault.
}
