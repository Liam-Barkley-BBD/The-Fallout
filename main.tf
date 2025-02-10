provider "aws" {
    region = "af-south-1
}

resource "aws_security_group" "postgres_sq" {
    name = "postgres-sg"
    description = "Allow access to PostgreSQL"

    ingress {
        from_port = 5432
        to_port = 5432
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

resource "aws_db_instance" "postgresql" {
    allocated_storage = 20
    db_instance_class = "db.t3.micro"
    engine = "postgres"
    engine_version = "14.4"
    instance_identifier = "fallout-db"
    db_name = "FalloutDB"
    username = "admin"
    password = "TheFallout"
    publicly_accessible = true
    vpc_security_group_ids = [aws_security_group.postgres_sq.id]
    skip_final_snapshot = true
    multi_az = false

    tags = {
        Name = "PostgreSQL"
    }
}