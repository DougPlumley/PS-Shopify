function Get-ShopifyProduct
{
    <#
    .Synopsis
       This function uses the Shopify REST API to pull a list of products from a given store.
    .DESCRIPTION
       This function uses the Shopify REST API to pull a list of products from a given store.  The products are returned as PSCustomObjects and can be used to manipulate data locally before updating products in the Shopify store.
    .EXAMPLE
       Get-ShopifyProduct -StoreName "My-Shopify-Store" -Credential (Get-Credential ca7af3a5-ea25-4563-ae41-a1ea6a6ecf6a)
    #>
    [CmdletBinding()]
    [Alias()]
    [OutputType([PSCustomObject])]
    Param
    (
        # Product SKU
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, Position=0)]
        [String]
        $Identity,

        # API key and password
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [PSCredential]
        $Credential,

        # Local storename only, example: "My-Shopify-Store"
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=2)]
        [String]
        $StoreName,

        [String]
        [ValidateScript({$_ -like "Unlimited" -or $_ -as [int]})]
        $ResultSize = 5
    )

    Begin
    {
        $StoreURL = "https://$($StoreName).myshopify.com/admin"

        $headers = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Credential.UserName+":" + $Credential.GetNetworkCredential().Password))}
    }
    Process
    {

        $products = @()
        $page = 1

        if ($ResultSize -like "Unlimited") {
            $Unlimited = $true
            $ResultSize = 250
        } 
        else {
            $Unlimited = $false
        }

        # Get all parts
        do {
            Write-Verbose "Searching for parts, ResultSize = $($ResultSize) and Page = $($page)"
            $products += $results = (Invoke-RestMethod -Uri "$($StoreURL)/products.json?limit=$($ResultSize)&page=$($page)" -ContentType "application/json" -Method Get -Headers $headers).products
            $page++
        }
        while (($Unlimited -and $results.Count -eq 250) -or (!$Unlimited -and $products.count -lt $ResultSize))

        if ($Identity) {$products = $products | Where-Object {$_.variants.sku -like "*$($Identity)*"}}

        return $products
    }
    End
    {
    }
}

function New-ShopifyProduct
{
    <#
    .Synopsis
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       Example of how to use this cmdlet
    .EXAMPLE
       Another example of how to use this cmdlet
    #>
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
        [String]
        $Title,

        # Local storename only, example: "My-Shopify-Store"
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [String]
        $StoreName,

        # API key and password
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=2)]
        [PSCredential]
        $Credential,

        [PSCustomObject[]]
        $Images,

        [String]
        $Vendor,

        # Weight in US pounds (lbs)
        [float]
        $Weight,

        [String]
        $ProductType,

        # Body as HTML
        [String]
        $Body
    )

    Begin
    {
        $headers = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Credential.UserName+":" + $Credential.GetNetworkCredential().Password))}

        $StoreURL = "https://$($StoreName).myshopify.com/admin/products.json"
    }
    Process
    {
        Write-Verbose "Verifying product does not already exist."
        $products = Get-ShopifyProduct -ResultSize Unlimited -Credential $Credential -StoreName $StoreName
        if ($products.title -notcontains $Title) {
            Write-Verbose "SKU $($SKU) doesn't exist, adding SKU."
        }
        else {
            throw "$($Title) already exists in Shopify"
        }

        # Base product template
        $product = [PSCustomObject] @{
            product = [PSCustomObject] @{
                title = $Title
            }
        }

        # Add to base product by parameter

        ##########################################################################
        # IMAGES
        ##########################################################################

        if ($Images) {
            Write-Verbose "Adding images to payload..."
            $encodedImages = @()

            foreach ($image in $images) {
                $encodedImages += [PSCustomObject] @{attachment = [convert]::ToBase64String($image.Image)}
            }

            $product.product | Add-Member -Name "images" -Value $encodedImages -MemberType NoteProperty -Force
        }

        if ($Vendor) {
            Write-Verbose "Adding vendor of $($Vendor)"
            $product.product | Add-Member -Name "vendor" -Value $Vendor -MemberType NoteProperty -Force
        }

        if ($Weight) {
            Write-Verbose "Adding weight of $($Weight)"
            $product.product.variants | Add-Member -Name "weight" -Value $Weight -MemberType NoteProperty -Force
            $product.product.variants | Add-Member -Name "weight_unit" -Value "lb" -MemberType NoteProperty -Force
        }

        if ($ProductType) {
            Write-Verbose "Adding product type of $($ProductType)"
            $product.product | Add-Member -Name "product_type" -Value $ProductType -MemberType NoteProperty -Force
        }

        if ($Body) {
            Write-Verbose "Adding HTML body."
            $product.product | Add-Member -Name "body_html" -Value $Body -MemberType NoteProperty -Force
        }

        $body = $product | ConvertTo-Json -Depth 10

        Invoke-WebRequest -Uri $StoreURL -ContentType "application/json" -Method Post -Headers $headers -Body $body
    }
    End
    {
    }
}