# Azure Load Balancer Demo with Terraform

## What this does

- Creates RG, VNet, Subnet  
- Deploys two VMs: Linux & Windows  
- Creates External Load Balancer (public IP, port 80)  
- Creates Internal Load Balancer (private IP in subnet, port 80)  
- Associates VM NICs to backend pools of both LBs  
- Allows HTTP, SSH, RDP, and ICMP traffic  

## How to deploy

1. `terraform init`  
2. `terraform apply`  
3. Check outputs for IP addresses  
4. Connect to VMs and test LB functionality  

## Notes

- Password and username can be changed in `variables.tf` or via CLI  
- Clean up with `terraform destroy`  
