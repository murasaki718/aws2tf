#!/bin/bash

if [ "$1" == "" ]; then echo "must specify a stack name" && exit; fi
nested=() 
echo "#!/bin/bash" > commands.sh
echo "Stack resources not yet implemented ...." > unprocessed.log

echo "d=$d"

getstack () {

stackr=$($AWS cloudformation describe-stack-resources --stack-name $1 --query StackResources)
#if [[  $? -eq 254 ]];then
#    echo "stack $1 not found exiting ..."
#    exit
#fi

#echo $stackr | jq .
count=`echo $stackr | jq ". | length"`
#echo $count
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
        for i in `seq 0 $count`; do
            type=$(echo "$stackr" | jq  -r ".[(${i})].ResourceType")
            stat=$(echo "$stackr" | jq  -r ".[(${i})].ResourceStatus")
            
            if [[ "$type" == "AWS::CloudFormation::Stack" ]];then
                if [[ "$stat" == "CREATE_COMPLETE" ]];then 
                    as=$(echo "$stackr" | jq  -r ".[(${i})].PhysicalResourceId" | cut -f2 -d'/')
                    nested+=$(printf "\"%s\" " $as)    
                fi        
            fi
        done   
else
    echo "found 0 stacks exit"
    exit
fi
}

getstackresources () {
echo "get stack resources for $1"
stackr=$($AWS cloudformation describe-stack-resources --stack-name $1 --query StackResources)
#echo $stackr | jq .
count=`echo $stackr | jq ". | length"`
echo "stack resources $count"
echo "---> Getting $count resources for stack $1"
if [ $count -gt 0 ]; then
    count=`expr $count - 1`
        for i in `seq 0 $count`; do
            type=$(echo "$stackr" | jq  -r ".[(${i})].ResourceType")
            pid=$(echo "$stackr" | jq  -r ".[(${i})].PhysicalResourceId" | cut -f2 -d'/')
            parn=$(echo "$stackr" | jq  -r ".[(${i})].PhysicalResourceId" | tr -d '"')
            if [[ "$d" == "st" ]];then 
                echo "--> $type $pid $parn"
            fi
            echo "echo 'Stack $1 Importing $i of $count ..'" >> commands.sh
            case $type in
                AWS::Cloud9::EnvironmentEC2) echo "../../scripts/252-get-c9.sh $pid"  >> commands.sh ;;
                
                AWS::CodeArtifact::Domain)  echo "../../scripts/627-get-code-artifact-domain.sh $pid"  >> commands.sh ;;
                AWS::CodeArtifact::Repository)  echo "../../scripts/627-get-code-artifact-repository.sh $pid"  >> commands.sh ;;
                
                AWS::Cognito::IdentityPool) echo "../../scripts/770-get-cognito-identity-pools.sh $pid"  >> commands.sh ;;
                AWS::Cognito::IdentityPoolRoleAttachment) echo "echo '# $type $pid fetched as part of Identity pool..' " >> commands.sh ;;
                AWS::Cognito::UserPool) echo "../../scripts/775-get-cognito-user-pools.sh $pid"  >> commands.sh ;;
                AWS::Cognito::UserPoolClient) echo "echo '# $type $pid fetched as part of User & Identity pool..' " >> commands.sh ;;
                      
                AWS::DynamoDB::Table) echo "../../scripts/640-get-dynamodb-table.sh $pid"  >> commands.sh ;;

                AWS::EC2::Instance) echo "../../scripts/250-get-ec2-instances.sh $pid"  >> commands.sh ;;
                AWS::EC2::EIP)  echo "../../scripts/get-eip.sh $pid"  >> commands.sh ;;
                AWS::EC2::NatGateway)  echo "../../scripts/130-get-natgw.sh $pid"  >> commands.sh ;;
                AWS::EC2::NetworkAcl) echo "../../scripts/107-get-network-acl.sh $pid"  >> commands.sh ;;
                AWS::EC2::NetworkAclEntry) echo "echo '# $type $pid fetched as part of NetworkAcl..'" >> commands.sh ;;
                AWS::EC2::SubnetNetworkAclAssociation) echo "echo '# $type $pid fetched as part of NetworkAcl..'" >> commands.sh ;;
                AWS::EC2::InternetGateway)  echo "../../scripts/120-get-igw.sh $pid"  >> commands.sh ;;
                AWS::EC2::LaunchTemplate)  echo "../../scripts/eks-launch_template.sh $pid"  >> commands.sh ;;
                AWS::EC2::SecurityGroup)  echo "../../scripts/110-get-security-group.sh $pid"  >> commands.sh ;;
                AWS::EC2::SecurityGroupIngress) echo "echo '# $type $pid fetched as part of SecurityGroup..'" >> commands.sh ;; # fetched as part of Security Group
                AWS::EC2::VPCEndpoint)  echo "../../scripts/161-get-vpce.sh $pid" >> commands.sh ;;
                AWS::EC2::VPC) echo "../../scripts/100-get-vpc.sh $pid" >> commands.sh ;;
                AWS::EC2::Subnet) echo "../../scripts/105-get-subnet.sh $pid" >> commands.sh ;;
                AWS::EC2::RouteTable)  echo "../../scripts/140-get-route-table.sh $pid" >> commands.sh ;;
                AWS::EC2::Route) echo "echo '#  $type $pid  fetched as part of RouteTable..'" >> commands.sh ;;  # fetched as part of RouteTable
                AWS::EC2::SubnetRouteTableAssociation) echo "../../scripts/141-get-route-table-associations.sh $pid" >> commands.sh ;;
                AWS::EC2::VPCGatewayAttachment) echo "echo '#  $type $pid attached as part of IGW etc ..'" >> commands.sh ;; 

                AWS::ECR::Repository)  echo "../../scripts/get-ecr.sh $pid"  >> commands.sh ;;

                AWS::ECS::Cluster) echo "../../scripts/350-get-ecs-cluster.sh $pid" >> commands.sh ;;
                AWS::ECS::Service)  echo "../../scripts/get-ecs-service.sh $parn" >> commands.sh ;;
                AWS::ECS::TaskDefinition)  echo "../../scripts/351-get-ecs-task.sh $pid" >> commands.sh ;;
                
                AWS::EKS::Cluster) echo "../../scripts/300-get-eks-cluster.sh $pid" >> commands.sh ;;
                AWS::EKS::Nodegroup) echo "# $type $pid Should be fetched via the EKS Cluster Resource" >> commands.sh ;;
                
                AWS::ElasticLoadBalancingV2::LoadBalancer) echo "../../scripts/elbv2.sh $parn" >> commands.sh ;;
                AWS::ElasticLoadBalancingV2::Listener) echo "../../scripts/elbv2_listener.sh $parn" >> commands.sh ;;
                AWS::ElasticLoadBalancingV2::ListenerRule) echo "../../scripts/elbv2_listener-rules.sh $parn" >> commands.sh ;;
                AWS::ElasticLoadBalancingV2::TargetGroup) echo "../../scripts/elbv2-target-groups.sh $parn" >> commands.sh ;;

                AWS::Events::EventBus)  echo "../../scripts/712-get-eb-bus.sh $pid" >> commands.sh;;
                AWS::Events::Rule)  echo "../../scripts/713-get-eb-rule.sh \"$pid\"" >> commands.sh;;

                AWS::Glue::Database) echo "../../scripts/650-get-glue-database.sh \"$pid\"" >> commands.sh;;
                AWS::Glue::Table) echo "# $type $pid Should be fetched via Glue Database Resource" >> commands.sh ;;
                AWS::IAM::Role)  echo "../../scripts/050-get-iam-roles.sh $pid" >> commands.sh ;;
                AWS::IAM::ManagedPolicy) echo "../../scripts/get-iam-policies.sh $parn" >> commands.sh ;;
                AWS::IAM::Policy)  echo "../../scripts/get-iam-policies.sh $parn" >> commands.sh ;;
                AWS::IAM::InstanceProfile) echo "../../scripts/056-get-instance-profile.sh $pid" >> commands.sh ;;
                AWS::IAM::User) echo "../../scripts/030-get-iam-users.sh $pid" >> commands.sh ;;
                AWS::IAM::AccessKey) echo "../../scripts/057-get-iam-access-key.sh $pid" >> commands.sh ;;

                AWS::KinesisFirehose::DeliveryStream) echo "../../scripts/740-get-kinesis-firehose-delivery-stream.sh $pid" >> commands.sh ;;

                AWS::KMS::Key)  echo "../../scripts/080-get-kms-key.sh $pid" >> commands.sh ;;                
                AWS::KMS::Alias) echo "echo '#  $type $pid  fetched as part of function..'" >> commands.sh ;;  # fetched as part of function 
                
                AWS::Lambda::Function)  echo "../../scripts/700-get-lambda-function.sh $pid"  >> commands.sh ;;
                AWS::Lambda::Permission) echo "echo '# $type $pid fetched as part of function..'" >> commands.sh ;; # fetched as part of function
                AWS::Lambda::EventInvokeConfig) echo "echo '# $type $pid fetched as part of function..'" >> commands.sh ;; # fetched as part of function

                AWS::Logs::LogGroup)  echo "../../scripts/070-get-cw-log-grp.sh /$parn" >> commands.sh ;;
                
                AWS::S3::Bucket)  echo "../../scripts/060-get-s3.sh $pid" >> commands.sh ;;
                
                AWS::SageMaker::AppImageConfig) echo "../../scripts/get-sagemaker-app-image-config.sh $pid" >> commands.sh ;;
                AWS::SageMaker::Domain) echo "../../scripts/680-get-sagemaker-domain.sh $parn" >> commands.sh ;;
                AWS::SageMaker::Image) echo "../../scripts/get-sagemaker-image.sh $pid" >> commands.sh ;;
                AWS::SageMaker::ImageVersion) echo "echo '# $type $pid fetched as part of SageMaker Image..'" >> commands.sh ;; # fetched as part of function

                AWS::SNS::Topic)  echo "../../scripts/730-get-sns-topic.sh $parn" >> commands.sh ;;
                AWS::SNS::TopicPolicy) echo "../../scripts/get-iam-policies.sh $parn" >> commands.sh ;;
                AWS::SQS::Queue)  echo "../../scripts/720-get-sqs-queue.sh $parn" >> commands.sh ;;
                
                AWS::SSM::Parameter)  echo "../../scripts/445-get-ssm-params.sh $pid" >> commands.sh ;;
                
                AWS::SecretsManager::Secret)  echo "../../scripts/450-get-secrets.sh $parn"  >> commands.sh ;;                
                AWS::ServiceDiscovery::Service)  echo "../../scripts/get-sd-service.sh $pid"  >> commands.sh ;;

                AWS::CloudFormation::WaitCondition*) echo "skipping $type" ;;
                AWS::CloudFormation::Stack) ;;

                *) echo "--UNPROCESSED-- $type $pid $parn" >> unprocessed.log ;;
esac
        done   
fi
    
}



echo "level 1 nesting"
getstack $1
echo "level 2 nesting"
for nest in ${nested[@]}; do
    nest=`echo $nest | jq -r .`
    getstack $nest
done
nested+=$(printf "\"%s\" " $1)
echo "Stacks Found:"
for nest in ${nested[@]}; do
    nest=`echo $nest | jq -r .`
    echo "$nest"

done

for nest in ${nested[@]}; do
    nest=`echo $nest | jq -r .`
    getstackresources $nest
    
done
echo "echo \"Commands Done ..\"" >> commands.sh 
#echo "commands.sh"
#cat commands.sh


