# IAM User
resource "aws_iam_user" "jenkins_user" {
  name = "ansible_user"
}

# IAM Access Key
resource "aws_iam_access_key" "jenkins_user_key" {
  user = aws_iam_user.jenkins_user.name
}
#IAM Group
resource "aws_iam_group" "jenkins_group" {
  name = "jenkins_group"
}

# ansible user to ansible group
resource "aws_iam_user_group_membership" "jenkins_group_membership" {
  user   = aws_iam_user.jenkins_user.name
  groups = [aws_iam_group.jenkins_group.name]
}

resource "aws_iam_group_policy_attachment" "jenkins_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  group      = aws_iam_group.jenkins_group.name
}