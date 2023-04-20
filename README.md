# Terraform-Azure-Enterprise-Scale-Accelerator

This repository standardizes and automates:
1) the deployment of an Azure backend storage for Terraform state file management (Launchpad)
2) a bootstrapping procedure for creating Terraform configuration files required by [terraform-azurerm-caf-enterprise-scale](https://github.com/Azure/terraform-azurerm-caf-enterprise-scale)

</br>

# In a Nutshell

You:
1) fill out **bootstrap.yaml**
2) execute **setup-launchpad.sh**
3) execute **bootstrap-enterprise-scale.sh** and **Terraform** to deploy Enterprise Scale resources

Please read the next chapters for detailed instructions.

</br>

# Prepare Host for Setup Procedure

</br>

**1) Copy Content**
- Create a copy of this repo in your own [Github Organization](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/about-organizations).

**2) Host**
- Clone your new repository to the machine on which the setup procedure will be executed (e.g. local notebook).

**3) Visual Studio Code**
- [Download](https://code.visualstudio.com/Download) and install Visual Studio Code (VSC).
- Enable [Devcontainer](https://code.visualstudio.com/docs/devcontainers/tutorial) on VSC.

**4) Devcontainer**
- Open VSC and click on the [Explorer](https://code.visualstudio.com/docs/getstarted/userinterface#_explorer) to open your repository. Choose [Reopen in Container](https://code.visualstudio.com/docs/devcontainers/create-dev-container#_add-configuration-files-to-a-repository) when prompted.
- VSC opens your workspace in a devcontainer with access to the script files and executables.

</br>

# Setup Launchpad

</br>

**5) Launchpad Azure Subscription**
- Create an Azure [subscription](https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/create-subscription) on which the Launchpad resources will be deployed.

**6) Azure Automation User**
- Create an [Azure Service Principal](https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal) which will be used as an automation user to authenticate to Azure.
- Assign the [Owner](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles) built-in role to the Service Principal with scope on the [Tenant Root Group](https://learn.microsoft.com/en-us/azure/governance/management-groups/overview).
- Create a Service Principal [secret](https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/service-accounts-principal#service-principal-authentication).

**7) Installation**
- Edit **bootstrap.yaml** according to your needs.
- Start the installation script by executing:
> ./**setup-launchpad.sh** -i 'Service Principal Application/Client ID>' -s 'Service Principal Secret'


**8) Azure Resources**
- Inspect the [main.tf](https://github.com/rigydi/terraform-azurerm-launchpad/blob/main/main.tf) file to see which resources will be deployed.

**9) Terraform State File**
- In the last step of the installation procedure, the installation script will configure the [Azure Backend](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm) to host the [Terraform state file](https://developer.hashicorp.com/terraform/language/state).

<br/>

# Setup Terraform Enterprise Scale
<br/>

**10) Settings**
- Adjust **bootstrap.yaml** according to your needs.

**11) Bootstrap Terraform Enterprise Scale**
- Start the script by executing
> ./**bootstrap-enterprise-scale.sh**

**12) Execute**
- The script creates the required Terraform Enterprise Scale files according to your inputs. Adjust the Terraform files if required.
- Continue by using standard Terraform commands such as **terraform init** and **terraform apply**.

</br>

# Setup Diagram

![Diagram](./docs/Diagram.svg "Diagram")

</br>

# Examples

Examples can be found in the [examples](./examples/) folder.

</br>

# Documentation

Additional documentation can be found in folder [docs](./docs).