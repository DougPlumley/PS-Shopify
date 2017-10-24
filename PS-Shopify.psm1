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
        # API key and password
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
        [PSCredential]
        $Credential,

        # Local storename only, example: "My-Shopify-Store"
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [String]
        $StoreName,

        [String]
        [ValidateScript({$_ -like "Unlimited" -or $_ -as [int]})]
        $ResultSize = 5
    )

    Begin
    {
    }
    Process
    {
        $StoreURL = "https://$($StoreName).myshopify.com/admin"

        $headers = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Credential.UserName+":" + $Credential.GetNetworkCredential().Password))}

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

        return $products
    }
    End
    {
    }
}