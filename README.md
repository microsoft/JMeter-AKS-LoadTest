
# Project

Automated performance pipeline using Apache JMeter and AKS

As the Azure DevOps cloud-based load testing by Microsoft has been deprecated, we evaluated the options and finalized on using Apache JMeter with Azure Kubernetes Service (AKS) in a distributed architecture to carry out an intensive load test by simulating hundreds and thousands of simultaneous users.
 
 ![image](https://user-images.githubusercontent.com/81369583/114204849-499b3b00-9977-11eb-811d-2c2ff7248f11.png)


Currently we have also implemented an automated pipeline for running the performance test using Apache JMeter and AKS, which is also extended to simulate parallel load from multiple regions to reproduce a production scenario.

# Prerequisite for onboarding to the automated pipeline:

## JMeter test scripts:
  1.	create the test suite with the help of how to setup JMeter test plan(https://jmeter.apache.org/usermanual/build-web-test-plan.html).
  2.	Check in the JMX file and supporting files in a repository
## AKS setup 
  1.	Create  AKS cluster with the help of how to create a AKS cluster(https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal)
  2.	Provide access to a Service Principal Name which would be used to run the JMX file in the cluster.

## Steps to onboarding for the pipeline:
1.	Fork the YAML pipeline from the repository:  JMeterAKSLoadTest(https://github.com/microsoft/JMeterAKSLoadTest.git)
2.	Folder structure looks like below:
   ![image](https://user-images.githubusercontent.com/81369583/114205274-bf9fa200-9977-11eb-9588-3185151bb711.png)
   
3.	Inside the JMeterFiles folder add the JMX and supporting files there
   ![image](https://user-images.githubusercontent.com/81369583/114205337-d34b0880-9977-11eb-9b79-d728989469b0.png)
   
4.	Overview on the variable set up:
  - JMX file has below variables, which can be used from the variable group or pipeline variables according to the setup:
      1. PerfTestResourceId – Resource Id for the API Auth 
      2.	PerfTestClientId – Client Id for the API Auth 
      3.	PerfTestClientSecret – Client secret for the API Auth
      4.	JmeterFolderPath – JMX File folder path
      5.	JmeterFileName – JMX File name 
  - AKS set up related variables:
      1.	AKSClusterNameRegion1 -Cluster name of the respective region
      2.	AKSResourceGroupRegion1 – Cluster resource name for the region
      3.	AKSSPNClientIdRegion1 – client id for the region
      4.	AKSSPNClientSecretRegion1 – client secret for the region
      5.	TenantId – tenant id
      6.	CSVFileNames – list of supported file names for execution like “users.csv,ids.csv”
      
      ![image](https://user-images.githubusercontent.com/81369583/114205527-0097b680-9978-11eb-90a4-45bd8c0a7326.png)
5.	Set the mentioned pipeline variables as shown:
   ![image](https://user-images.githubusercontent.com/81369583/114205558-08575b00-9978-11eb-8b1c-999b00f8e924.png)

6.	Set the Variable group linked from Key vault.     

7.	The results of the execution is published as artifact and it can be downloaded. The index.html file holds the report of the run.

## Advantages:
  1.	With minimal cost you can simulate parallel load from different regions to replicate the production scenario.
  2.	As all the Loops, Threads and Ramp up time variables are configured through pipeline variables you can run the test suite with minimal changes
  3.	Once the setup is complete no dependency on any specific machine or user credential, therefore it could be run more frequently to understand the application performance.	
  
## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
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
