provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "main" {
    cidr_block = "10.1.0.0/16"
    tags = {
        Name = "Lobs VPC"
    }
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "Lobs IG"
    }
}

resource "aws_subnet" "main" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.1.1.0/24"
    availability_zone = "us-east-1a"
}

resource "aws_route_table" "default" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }
}

resource "aws_route_table_association" "main"{
    subnet_id = aws_subnet.main.id
    route_table_id = aws_route_table.default.id
}

resource "aws_network_acl" "allowall"{
    vpc_id = aws_vpc.main.id
    egress {
        protocol = "-1"
        rule_no = 100
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = 0
        to_port = 0
    }

    ingress {
        protocol = "-1"
        rule_no = 100
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = 0
        to_port = 0
    }
}


resource "aws_security_group" "allowall" {
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_eip" "webserver" {
    instance = aws_instance.webserver.id
    vpc = true
    depends_on = [aws_internet_gateway.main]
}

resource "aws_key_pair" "default" {
    key_name = "lobs_tf"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRd5zm7lH0w58F/T9SHT9eEO5xwwQ7LPAwIJTwKWM1M0OwgTzNxSm5bOjO1XY8iyeFgJ8kVRs25oGtOugE33cVie6Ca8ApOAg0SJPua0TN4E1YY+JSHJkrvBbWIWRFBeQA2pWRp4OsOyV6vS0SxqAkQONiTrTAOKpaMlxYhmlOlSu7ZHV16nSfL1ZagAsgj+J+a04RaLsVtiBdWeZ1PKYNRvj35dYpclesKIt8ukVGu8BfbMThsnpNFHem2QzSMsKeuw3fqhlIJ6v+x1hh5KC4tCfDJVldR27kkjQF8jBlU3cDvNQ4OHbcLReHeXUQyB9j7FtkJhHUtKROwXUVB8P5 xyz"
}

data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"]
}

resource "aws_instance" "webserver" {
    ami = data.aws_ami.ubuntu.id
    availability_zone = "us-east-1a"
    instance_type = "t3.small"
    key_name = aws_key_pair.default.key_name
    vpc_security_group_ids = [aws_security_group.allowall.id]
    subnet_id = aws_subnet.main.id
}