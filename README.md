# Azure VM cluster IaC with Terraform and GitHub Actions

## Project goal

The project goal is to build an automation that deploys Application Gateway with WAF and LoadBalancer and VM cluster (3 nodes) on Azure. Install Nginx and mySQL on all VMs via user_data script. All by Terraform and GitHub Action as code. (We also build a manual Destroy Workflow.)

*(Although the code works in a prod environment, the main goal of this project is DevOps automation learning in Azure environment.)*

## How to use

1. Complete the preparation steps below, make sure you note your own Azure environemnt ID-s. 
2. Get all the files from this repo and replace the related ID-s to yours in the code files, also don't forget to create your own Secrets on your GitHub repo.
3. Once you push the code to your own GitHub repo, it should automatically deploy everything.
4. You can destroy the deployment by running the destroy workflow manually in your GitHub repo Actions.

*note: the count of VM instances can be now adjusted in `variables.tf` > `vm_count` variable.*

## Azure preparation

**Prerequisites and preparation steps:**
- [ ] Register an Azure free account
- [ ] Create an Azure Resource Group
- [ ] Create Azure Storage Account and Container for Terraform State
- [ ] Create Azure AD Application Registration & Service Principal
- [ ] Configure Federated Credential for OIDC
- [ ] Register Resource providers


### Create an Azure Resource Group

This is a logical container that holds realted resources for the project

**How to do it:**
Azure Portal > Resource Groups > Create

Subscription: *Choose your subscription*   
Name: `rg-azure-iac-p1`   
Region: `(Europe) West Europe`

### Create Azure Storage Account and Container for Terraform State

We need a Storage Account > Blob Storage service to store the Terraform state file. 

**How to do it:**
Azure Portal > Storage accounts > Create

Name: `azuretfstatep1` *(name it as you wish, only letters and numbers accepted)*   
Primary service: `Azure Blob Storage...`  
Performance: `Standard...`  
Redundancy: `Locally-redundant storage (LRS)`

#### Create Container

After the storage acocunt is created go to Azure Portal > Storage accounts > *(your account)* > Data Storage > Containers > Add container   

Name: `tfstate` *(common convention)*

### Create Azure AD Application Registration & Service Principal

We need to register an Application in Azure Active Directory (Azure AD). This registration automatically creates an associated Service Principal, which is the identity our GitHub Actions workflow will use to authenticate to Azure.

**How to do it:**
Azure Portal > App registrations > New registration

Name: `github-actions-tuser1` *(name it and note it, as you wish)*   
Supported account types: `Accounts in this organizational directory only (Default Directory only - Single tenant)`   

Once the app is registered, you'll be taken to its overview page.
Note: From this "Overview" page, copy and save the Application (client) ID and the Directory (tenant) ID. These are crucial.

Next steps:

#### Grant Contributor role on the Resource Group

**How to do it:**
Azure Portal > Resource Groups > Access control (IAM) > Add role assignment > Privileged administrator roles tab   

Select: `Contributor`   
Assign access to: `User, group, or service principal`   
Members: Select members > In the right-hand pane, search for the name of the App Registration you created in the previous steps.

#### Grant Storage Blob Data Contributor role on the Storage Account

**How to do it:**
Azure Portal > Storage accounts > ... > Add role assignment >   

Select: `Storage Blob Data Contributor`    
Assign access to: `User, group, or service principal`   
Members: Select members > In the right-hand pane, search for the name of the App Registration you created in the previous steps.

### Configure Federated Credential for OIDC

This step creates a trust relationship between your Azure AD Application and your GitHub repository. It allows GitHub Actions to obtain temporary access tokens from Azure without needing to store any Azure secrets in GitHub.

**How to do it:**
Azure Portal > App registrations > *your app* > Manage > Certificates & secrets > Federated credentials > Add credential

Federated credential scenario: `GitHub Actions deploying Azure resources`   
organization: `<your GitHub username> `   
Repository: `<your GitHub repo>`   
Entity Type: `Branch`   
GitHub branch name:  `your GitHub branch name`   
Name: `github-main-branch-federation`  *(name as you wish)*   

### Register resource Providers

#### Microsoft.Compute provider

**How to do it:** 
Azure Portal > Subscriptions > *(your subscription)* > Settings (in left menu) > Resource providers >   
Search for `Microsoft.Compute` > Select and register

## Terraform code files 

`provider.tf`, `backend.tf`, `variables.tf`, `main.tf`, `outputs.tf`

## user_data script

`user_data.sh`   

## GitHub Actions setup and code files

### GitHub Secrets

Before this workflow can successfully run, you need to create the following Secrets in your GitHub repository settings:

`AZURE_CLIENT_ID`: The Application (Client) ID of the Azure AD App registration you created.   
`AZURE_SUBSCRIPTION_ID`: Your Azure Subscription ID.   
`AZURE_TENANT_ID`: Your Azure Directory (Tenant) ID.   
`ADMIN_SSH_PUBLIC_KEY`: The actual content of your SSH public key.   

### GitHub Actions workflow codes

#### Deployment workflow

`terraform_deploy.yml` file must be in the `.github/workflows/` folder

#### Destroy workflow (manual only)

`terraform_destroy.yml` file must be in the `.github/workflows/` folder too