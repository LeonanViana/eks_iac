#!/bin/bash
#Script para deploy do Eks

#Variáveis environment(dev/hlg/prd) | region(us-east-1) | bucket=(nome bucket)
REGION=us-east-1
CLUSTER_NAME=
AWS_ACCOUNT_ID=
VPC_ID=

# Id das subnets publicas e privadas
subnet_id_1= # Public
subnet_id_2= # Public
subnet_id_3= # Public
subnet_id_4= # Private
subnet_id_5= # Private
subnet_id_6= # Private

aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

AWS_OIDC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
AWS_SCALING_GROUP_NAME=$(aws autoscaling describe-auto-scaling-groups | grep AutoScalingGroupName | cut -d ':' -f 2 | cut -d '"' -f 2)

aws autoscaling create-or-update-tags \
  --tags ResourceId=$AWS_SCALING_GROUP_NAME,ResourceType=auto-scaling-group,Key=k8s.io/cluster-autoscaler/$CLUSTER_NAME,Value=owned,PropagateAtLaunch=true

aws autoscaling create-or-update-tags \
  --tags ResourceId=$AWS_SCALING_GROUP_NAME,ResourceType=auto-scaling-group,Key=k8s.io/cluster-autoscaler/enabled,Value=true,PropagateAtLaunch=true

#### Montar awk nos arquivos ###
#### Criar as variáveis dentro dos arquivos ###

awk -v cluster_name="${CLUSTER_NAME}" '{gsub(/- --cluster-name=\${CLUSTER_NAME}/, "- --cluster-name=" cluster_name)}1' cluster_loadbalancer/v2_4_7_full.yaml > temp_file && mv temp_file cluster_loadbalancer/v2_4_7_full.yaml
awk -v vpc_id="${VPC_ID}" '{gsub(/- --aws-vpc-id=\${VPC_ID}/, "- --aws-vpc-id=" vpc_id)}1' cluster_loadbalancer/v2_4_7_full.yaml > temp_file && mv temp_file cluster_loadbalancer/v2_4_7_full.yaml
awk -v aws_account_id="${AWS_ACCOUNT_ID}" '{gsub(/eks\.amazonaws\.com\/role-arn: arn:aws:iam::"\${AWS_ACCOUNT_ID}":role\/AmazonEKSLoadBalancerControllerRole/, "eks.amazonaws.com/role-arn: arn:aws:iam::" aws_account_id ":role/AmazonEKSLoadBalancerControllerRole")}1' cluster_loadbalancer/aws-load-balancer-controller-service-account.yaml > temp_file && mv temp_file cluster_loadbalancer/aws-load-balancer-controller-service-account.yaml
awk -v aws_default_region="${AWS_DEFAULT_REGION}" '{gsub(/\${AWS_DEFAULT_REGION}/, aws_default_region)}1' logs/fluentd-cloudwatch.yaml > temp_file && mv temp_file logs/fluentd-cloudwatch.yaml
awk -v cluster_name="${CLUSTER_NAME}" '{gsub(/\${CLUSTER_NAME}/, cluster_name)}1' logs/fluentd-cloudwatch.yaml > temp_file && mv temp_file logs/fluentd-cloudwatch.yaml
awk -v cluster_name="${CLUSTER_NAME}" '{gsub(/- --node-group-auto-discovery=asg:tag=k8s\.io\/cluster-autoscaler\/enabled,k8s\.io\/cluster-autoscaler\/\${CLUSTER_NAME}/, "- --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/" cluster_name)}1' cluster_autoscaler/cluster_autoscaler.yaml > temp_file && mv temp_file cluster_autoscaler/cluster_autoscaler.yaml
awk -v aws_oidc_id="${AWS_OIDC_ID}" '{gsub(/oidc-provider\/oidc\.eks\.us-east-1\.amazonaws\.com\/id\/\${AWS_OIDC_ID}/, "oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/" aws_oidc_id)}1' iam/load-balancer-role-trust-policy.json > temp_file && mv temp_file iam/load-balancer-role-trust-policy.json
awk -v aws_oidc_id="${AWS_OIDC_ID}" '{gsub(/oidc\.eks\.us-east-1\.amazonaws\.com\/id\/\${AWS_OIDC_ID}/, "oidc.eks.us-east-1.amazonaws.com/id/" aws_oidc_id)}1' iam/load-balancer-role-trust-policy.json > temp_file && mv temp_file iam/load-balancer-role-trust-policy.json
awk -v aws_account_id="${AWS_ACCOUNT_ID}" '{gsub(/"Federated": "arn:aws:iam::\${AWS_ACCOUNT_ID}/, "\"Federated\": \"arn:aws:iam::" aws_account_id)}1' iam/load-balancer-role-trust-policy.json > temp_file && mv temp_file iam/load-balancer-role-trust-policy.json


eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve

#### Ajustar Tags VPC
aws ec2 create-tags --region $AWS_DEFAULT_REGION --resources $subnet_id_1 --tags Key="kubernetes.io/cluster/$CLUSTER_NAME",Value=shared
aws ec2 create-tags --region $AWS_DEFAULT_REGION --resources $subnet_id_1 --tags Key="kubernetes.io/role/elb",Value=1
aws ec2 create-tags --region $AWS_DEFAULT_REGION --resources $subnet_id_2 --tags Key="kubernetes.io/cluster/$CLUSTER_NAME",Value=shared
aws ec2 create-tags --region $AWS_DEFAULT_REGION --resources $subnet_id_2 --tags Key="kubernetes.io/role/elb",Value=1
aws ec2 create-tags --region $AWS_DEFAULT_REGION --resources $subnet_id_3 --tags Key="kubernetes.io/cluster/$CLUSTER_NAME",Value=shared
aws ec2 create-tags --region $AWS_DEFAULT_REGION --resources $subnet_id_3 --tags Key="kubernetes.io/role/elb",Value=1
aws ec2 create-tags --region $AWS_DEFAULT_REGION --resources $subnet_id_4 --tags Key="kubernetes.io/cluster/$CLUSTER_NAME",Value=shared
aws ec2 create-tags --region $AWS_DEFAULT_REGION --resources $subnet_id_4 --tags Key="kubernetes.io/role/internal-elb",Value=1
aws ec2 create-tags --region $AWS_DEFAULT_REGION --resources $subnet_id_5 --tags Key="kubernetes.io/cluster/$CLUSTER_NAME",Value=shared
aws ec2 create-tags --region $AWS_DEFAULT_REGION --resources $subnet_id_5 --tags Key="kubernetes.io/role/internal-elb",Value=1
aws ec2 create-tags --region $AWS_DEFAULT_REGION --resources $subnet_id_6 --tags Key="kubernetes.io/cluster/$CLUSTER_NAME",Value=shared
aws ec2 create-tags --region $AWS_DEFAULT_REGION --resources $subnet_id_6 --tags Key="kubernetes.io/role/internal-elb",Value=1

## Configuração dos Deployments
kubectl apply -f rbac/alb-rbac.yaml
kubectl apply -f logs/fluentd-cloudwatch.yaml

cd cluster_autoscaler 
aws iam create-policy --policy-name k8s-asg-policy --policy-document file://k8s-asg-policy.json
kubectl apply -f cluster_autoscaler.yaml
cd ..

kubectl apply -f observability/high-availability.yaml

cd iam
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json
aws iam create-role --role-name AmazonEKSLoadBalancerControllerRole --assume-role-policy-document file://load-balancer-role-trust-policy.json
aws iam attach-role-policy --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy --role-name AmazonEKSLoadBalancerControllerRole
cd ..

kubectl apply --validate=false -f cluster_loadbalancer/cert-manager.yaml
kubectl apply -f cluster_loadbalancer/aws-load-balancer-controller-service-account.yaml

sleep 30

kubectl apply -f cluster_loadbalancer/v2_4_7_full.yaml
kubectl apply -f cluster_loadbalancer/v2_4_7_ingclass.yaml

exit



