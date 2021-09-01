# Project

Automated Performance Pipeline using Apache JMeter and AKS

As the Azure DevOps cloud-based load testing by Microsoft has been deprecated, we evaluated the options and finalized on using Apache JMeter with Azure Kubernetes Service (AKS) in a distributed architecture to carry out an intensive load test by simulating hundreds and thousands of simultaneous users.

![image](https://user-images.githubusercontent.com/81369583/114204849-499b3b00-9977-11eb-811d-2c2ff7248f11.png)

Currently we have also implemented an automated pipeline for running the performance test using Apache JMeter and AKS, which is also extended to simulate parallel load from multiple regions to reproduce a production scenario.

## Prerequisite for onboarding to the automated pipeline:

Prerequisite script creates Service Connection, App Id, Service Principal and KeyVault. KeyVault has certificate and client secret.
Steps to execute Prerequisite script:

1. Set working directory to Scripts folder where Prerequisite.ps1 resides.
2. Run below command.

   .\Prerequisite -subscriptionId {Azure Subscription Id} -resourceGroupName {Resource Group Name} -keyVaultName {KeyVault Name} -location {Location} -certName {Certificate Name} -servicePrincipalName {Service Principal Name} -tenantId {Microsoft Tenand Id} -serviceConnectionName {Service Connection Name} -organizationName 'https://microsoftit.visualstudio.com' -projectName 'OneITVSO' -ServicePrincipalSecret {Service Principal Sercret Name}

3. After execution of Prerequisite script, Search Service Principal Name in Azure Active Directory and fetch App Id.
4. Onboard App Id to resource group with Contributor role.

## JMeter test scripts:

1. create the test suite with the help of how to setup JMeter test plan(https://jmeter.apache.org/usermanual/build-web-test-plan.html).
2. Check in the JMX file and supporting files in a repository

## AKS setup

1. Create AKS cluster with the help of how to create a AKS cluster(https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal)
2. Provide access to a Service Principal Name which would be used to run the JMX file in the cluster.

## Steps to onboard and execute the pipeline:

1. Fork the test execution YAML pipeline from the repository: JMeterAKSLoadTest(https://github.com/microsoft/JMeterAKSLoadTest.git)
2. Folder structure looks like below
   ![Folder Structure](./Images/folder-structure.png)

3. Inside the JMeterFiles folder add the JMX and supporting files there
   ![JMeter Files](./Images/JMeter-files.png)

4. Overview on the test execution pipeline variables which can be added by users before running the pipeline -

- Tenant – tenant id
- NameSpace - namespace
- ServiceConnection - azure service connection
- KeyVaultName - key vault name for fetching the secrets used in the pipeline
- SecretNames - list of secrets which can be fetched from the key vault e.g. "AKSSPNClientSecret, PerfTestClientSecret"
- AKSResourceGroup - resource groups for keeping AKS resources
- AKSRegion1 - Respective region name e.g. westus2
- AKSRegion2 - Respective region name e.g. cus
- AKSClusterNameRegion1 - cluster name of the respective region
- AKSClusterNameRegion2 - cluster name of the respective region
- AKSSPNClientId – service principal id used for connecting to AKS clusters
- AKSSPNClientSecret – client secret used for connecting to AKS clusters
- PerfTestResourceId – Resource Id for the API Auth
- PerfTestClientId – Client Id for the API Auth
- CSVFileNames – list of supported file names for execution like “users.csv,ids.csv”
  ![Pipeline variables](./Images/pipeline-variables.png)

5. Overview on the test execution pipeline parameters which can be configured at every run while running the pipeline -

- IsMultiRegionEnabled - allows user to optionally choose to run their workloads in more than one region
- IsClusterRequired - allows users to optionally create and tear down the cluster on demand while running the tests
- JMeterFolderPath – JMX File folder path
- JMeterFileName – JMX File name
- Threads - number of threads
- Duration - duration of the test
- Loops - number of loops
- RampUpTime -Ramp up time used to generate load from JMX file
  ![Pipeline parameters](./Images/pipeline-parameters.png)

6. The results of the execution is published as artifact and it can be downloaded. The index.html file holds the report of the run.

## Advantages:

1. With minimal cost you can simulate parallel load from different regions to replicate the production scenario.
2. As all the Loops, Threads and Ramp up time variables are configured through pipeline variables you can run the test suite with minimal changes
3. Once the setup is complete no dependency on any specific machine or user credential, therefore it could be run more frequently to understand the application performance.

## Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
