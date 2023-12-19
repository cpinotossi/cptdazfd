
Create an Azure Front Door for your AppService / Virtual Machine {#create-an-azure-front-door-for-your-appservice--virtual-machine}
================================================================

Summary
-------

In order to deliver your application securely it is required to have a web application firewall (WAF) in front of your application. This is also
documented in the Corporate Rule Base.

The Azure WAF Service is offered via two different services at Azure:
- Azure Front Door
- Azure Application Gateway

This documentation is explaining step by step how you can implement the Azure WAF in combination with Azure Front Door in front of an existing web application.

Reference: NM\_5.2.12 in [CRB - Information Security Network
Management](https://confluence.basf.net/display/CRB/Information+Security+Network+Management)


Prerequisites
-------------
- Azure Subscription
- Fully Qualified Domain Name (FQDN) for your application
 - If you do not have a FQDN you can request one via [Service4You](https://service4you.intranet.basf.com/esc?id=sc_cat_item&table=sc_cat_item&sys_id=5ca7e25f1b72741cef200edacd4bcba8)

Azure Front Door Concepts you need to know
------------------------------------------

### Azure Front Door Request Flow

The reqeust flow without Azure Front Door looks like this:

1. The client sends a request to the Application
2. The Application does receive the request and sends a response back to the client.

~~~mermaid
graph LR
A[ 1. Client] --request--> D[ 2. BASF Application
Backend Domain: backend-www.basf.de]
~~~

The request flow consist of 3 main steps:
1. The client sends a request to the Front Door Edge
2. The Front Door Edge validates via the WAF the request.
3. The Front Door Edge forwards the request to the backend if not blocked by the WAF. the backend does receive the request and sends a response back to the Front Door Edge which does forward the response to the Client.

~~~mermaid
graph LR
A[ 1. Client] --request--> B[ 2. Azure Front Door Edge]
B --Verify--> C[Azure WAF]
C --forward--> D[ 3. BASF Application
Backend Domain: backend-www.basf.de]
~~~

To be able to intercept the communication between the Backend and the Client Azure Front Door needs to be the recipien of the incoming client request. This is done via DNS. Azure Front door needs to take over the  FQDN of the Application. This is done by creating a CNAME record in the DNS. The CNAME record needs to point to the default frontend hostname. How exactly this is done is explained during this document.

### Endpoint, FQDN, Domains, Hostname at Azure Front Door

You need to have good understanding of the different terms used at Azure Front Door for DNS names/FQDN.

Inside the Microsoft Azure Documentation FQDNs are mentioned with different names: 
- "Endpoint"
- "Frontend domain/hostname"
- "default frontend domain/hostname"
- "custom frontend domain/hostname"
- "Backend domain/hostname"

~~~mermaid
classDiagram
direction LR
class Client {
  + Web Browser
}
class Front Door Edge {
 + Endpoint
 + Frontend domain/hostname
 + custom domain/hostname
}
class Backend {
 + Backend domain/hostname
}
Client <--> Front Door Edge
Front Door Edge <--> Backend
~~~

### frontend domains/hostnames
Does refer to the FQDN used by the Client to access the application.
We destinguish between 
- default frontend hostname/Endpoint and 
- custom frontend hostname. 

#### Endpoint, Default frontend hostname
The default frontend hostname/Endpoint will be created by default with each new azure Front Door Profile for you. Depending on the Azure Front Door Tier your default frontend hostname/Endpoint (aka endpoint) will look like this:
- Standard or Classic: (your Front Door Name).azurefd.net
- Premium: (your Front Door Name).azureedge.net
> [!NOTE] (your Front Door Name) can be freely chosen by you. It does not need to have any relation to your application name or domain name. But it needs to be unique inside Azure. The Azure Portal will tell you if the name is already taken.

##### Custom frontend domain/hostname
The custom frontend domain/hostname becomes interesting if you like to serve clients via your own FQDN instead of using the once provided via Front Door Endpoint/Default frontend hostname. Example of such a FQDN could be www.basf.de. This custom frontend domain/hostname needs to be registered in the DNS. The DNS needs to point to the default frontend hostname/endpoint. This is done by creating a CNAME record in the DNS. The CNAME record needs to point to the default frontend hostname.

~~~mermaid
graph LR
A[ Custom frontend domain/hostname
www.basf.de] --CNAME--> B[ Default frontend hostname/endpoint
basf.azureedge.net or basf.azurefd.net]
~~~

> [!WARNING] Creation of the CNAME record which does point the ***custom frontend hostname*** to the ***default frontend hostname/Endpoint*** will result into delivering your application via the Azure Front Door. Therefore you should make sure to read the "How to got live" section of this document before creating the CNAME record.

#### "Backend hostname", "Backend Domains"
Does refer to the FQDN used by the Front Door Edge to access the backend, something like backend-www.basf.de. This could be a public IP address or a DNS name. The Backend host is configured in the Backend Pool of the Azure Front Door. In addition this could be an Azure Service like AppService or Azure Storage. A full list of supported Azure Services can be found [here](https://learn.microsoft.com/en-us/azure/Front Door/front-door-faq#what-type-of-resources-are-currently-compatible-as-an-origin-).

~~~mermaid
graph LR
A[Azure Front Door Edge
www.basf.de] --fwd Request--> B[ Backend
backend-www.basf.de]
~~~

> [!IMPORTANT] Backend hostnames cannot be the same as the Frontend hostnames. This would result into conflicts and the Azure Front Door would not work properly.


Connect to the Azure Portal and find your Subscription
------------------------------------------------------

1.  In order to connect to your Cloud Environment make sure to follow
    the instructions of [this
    OnePager](https://docs.cloudreference.basf.com/CT/CloudOnePager/Azure/ConnectToAzurePortal.html).

2.  After logging in go to **Subscriptions** and select your
    Subscription from the menu.

Create your WAF Policy
----------------------

> [!NOTE] This step is only required if you do not have a WAF Policy. In general it is recommended to create an WAF Policy before creating the Azure Front Door. This way you can select the WAF Policy during the creation of the Azure Front Door.

1.  Navigate to your designated resource group and click the **Create**
    Button in the top left.

![CreateFront Door-00](images/CreateFront Door-00.png)

2.  Search for **Web Application Firewall (WAF)** and click **Create**

3.  Fill out the missing fields accordingly, choose Front door tier
    **Classic** and change the Policy mode to **Prevention**.

You can also put it to Detection first for initial testing, but in the
long run this should be changed to the prevention mode.

> [!IMPORTANT] Turning on the WAF Policy in prevention mode will maybe block requests which are considered legitimate. Therefore it is recommended to start with the detection mode and monitor the logs for a while for already existing Application. Afterwards you can change the mode to prevention. This process is called "tuning" the WAF Policy. Please read the [Microsoft Documentation](https://learn.microsoft.com/en-us/azure/web-application-firewall/afds/waf-front-door-tuning?pivots=front-door-standard-premium) for more information. In case this is a new Application you can start with the prevention mode right away so you do not need to tune the WAF Policy afterwards and you can be sure that only legitimate requests are forwarded to your application.

Now you can **Review + create** to create your WAF Policy

Create your Azure Front Door (Tier: Classic)
--------------------------------------------

1.  Navigate to your designated resource group and click the **Create**
    Button in the top left.

2.  Search for **Front Door and CDN profiles** and click **Create/Front Door and CDN profiles**

3.  In the Compare offerings menu select **Explore other offerings** and
    below **Azure Front Door (classic)**. Afterwards select **Continue**

4.  Select your Subscription and Resource group and continue with
    **Next: Configuration \>**

5.  Create your frontend host by clicking on **+** next to "Frontends/domains"

6. Enter the Custom Hostname,fitting hostname (can be anything) under "host name".

7. Select **Enabled** under **Web Application Firewall** and select your WAF Policy which you created beforehand. Afterwards click **Add**.

<!-- ![CreateFront Door-01](images/CreateFront Door-01.png) -->
6.  Create your backend pool for your frontend host to connect to by
    clicking on **+**

![CreateFront Door-02](images/CreateFront Door-02.png)

Select your Backend host type accordingly: - Virtual Machine: Public IP
Address - AppService: App service

Choose a Backend host header, set Status to **Enabled** and click
**Add**

7.  Create your routing rule by clicking on **+**

Define your accepted protocols and Route type. In case of using a custom
subdomain it is recommended to use route type **Redirect** and creating
a permanent redirect (308) to the URL.

8.  In order to stay secure it is recommended to create another routing
    rule called something along the lines of *http-to-https-redirect*
    which has accepted protocol **HTTP only** and forwarding protocol
    **HTTPS only**. When configuring this please change the forwarding
    protocol in your default routing rule to **Match request**. This way
    you can guarantee only HTTPS requests to your web application.

9.  Select **Review + create** to finish setting up your Front Door

Reassigning your DNS name / subdomain {#reassigning-your-dns-name--subdomain}
-------------------------------------

In case you are using a BASF domain like example.basf.com this needs to
be reassigned to the Front Door.

1.  Select your newly created Front Door and identify the Frontend host
    from the Overview page.

2.  Navigate to [this Service4You
    article](https://service4you.intranet.basf.com/sp?id=sc_cat_item&sys_id=3411ead91b313410f6cafc0b8b4bcbaf)
    to change your subdomain (can only be done by the Owner).

3.  Select your domain and as the new destination enter the Frontend
    host of the Front Door

This might take one or two days to complete so you will need to wait
before you continue with the next steps

TODO: It is unclear to myself if this process will result into a CNAME of the current custom domain to be CNAMED to the Front Door Endpoint or if this will just introduce the temporary afdverify sbdomain validation mentioned here:
https://learn.microsoft.com/en-us/azure/frontdoor/front-door-custom-domain#map-the-temporary-afdverify-subdomain




Adding your new subdomain to the Front Door
------------------------------------------

1.  Navigate to the Front Door designer and add a new Frontend/domain by
    selecting **+**

2.  As custom hostname enter your subdomain, enable the Web
    ApplicationFirewall setting and choose your WAF Policy. Now you can
    click **Add** to add the new domain to your configuration.

Configure your application to only allow traffic through Front Door
------------------------------------------------------------------

1.  Navigate to your Network Security Group (NSG) and go to **Inbound
    security rules**

2.  Identify your rules for HTTP and HTTPS and change the Source to
    **Service Tag** and the Source service tag to
    **AzureFront Door.Backend**.

This way only requests that are directly routed through the Front Door
will be forwarded to your application. If this is not configured people
do not have to go through Front Door which pretty much removes its
purpose.

Cloud\@BASF Contacts {#cloud-contacts}
--------------------

[Request Form
Service4You](https://service4you.intranet.basf.com/esc?id=sc_cat_item&table=sc_cat_item&sys_id=5ca7e25f1b72741cef200edacd4bcba8)

[Homepage
Cloud\@BASF](https://basf.sharepoint.com/sites/cloud-at-basf/SitePages/Welcome.aspx)

[BASF Cloud Reference Documents](https://docs.cloudreference.basf.com)

[All about Azure](https://azure.microsoft.com)

::: {.contribution .d-print-none}
[Edit this
page](https://dev.azure.com/BASFReference/BASFCloudReferenceArchitecture/_git/CRAWeb?path=web/CT/CloudOnePager/Azure/CreateFront Door.md&version=GBmaster&line=1){.edit-link}
:::

::: {#nextArticle .next-article .d-print-none .border-top}
:::
:::

::: {.affix}
:::
:::

::: {#search-results .container-xxl .search-results}
:::

::: {.container-xxl}
::: {.flex-fill style="margin-bottom: 10px;"}
Copyright © BASF Digital Solutions\
Generated by **CNC&E**\
Build: **App-CI-CRA - 2023-12-08.07 - master - 3760** Build-Branch:
**master**
:::
:::
