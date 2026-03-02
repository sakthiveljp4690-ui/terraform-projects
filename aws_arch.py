from diagrams import Diagram, Cluster
from diagrams.aws.network import VPC, InternetGateway, NATGateway, ELB, PrivateSubnet, PublicSubnet
from diagrams.aws.compute import EC2
from diagrams.aws.database import RDS
from diagrams.aws.management import SystemsManager
from diagrams.aws.network import PrivateSubnet

with Diagram("Production alike Two tier Architecture", show=True):

    igw = InternetGateway("Internet")

    with Cluster("VPC 10.1.0.0/16\nap-northeast-1"):

        with Cluster("Public Subnets (1a,1c)"):
            alb = ELB("ALB")
            nat = NATGateway("NAT Gateway")

        with Cluster("Private Subnet (1a,1c)"):
            app = EC2("App EC2\nIAM Role Attached\n(ssm ,rds-db-connect)")
            db = RDS("RDS MySQL\nIAM DB Auth Enabled")

            with Cluster("Interface Endpoints"):
                ssm_ep = PrivateSubnet("SSM Endpoint")
                ec2msg_ep = PrivateSubnet("EC2 Messages")
                ssmm_ep = PrivateSubnet("SSM Messages")

    igw >> alb >> app >> db
    app >> ssm_ep
    app >> ec2msg_ep
    app >> ssmm_ep
    app >> nat