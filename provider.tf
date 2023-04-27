provider "aws" {
  # NOTE Requires a profile configuration in .aws/config that'll be used for provisioning.
  # NOTE You can put for instance a role with all the requisite permissions in there.
  profile = "terraform"
}
