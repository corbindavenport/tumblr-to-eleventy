#Requires -Version 7.0

param (
    [Parameter(Mandatory = $true)][string]$key,
    [Parameter(Mandatory = $true)][string]$blog,
    [Parameter(Mandatory = $false)][string]$tag
)

[int]$RetrievedPosts = 0
[bool]$ContinueSearching = $true

function Get-Tumblr-Posts {
    Param(
        [Parameter(Mandatory = $true)][string]$ApiKey,
        [Parameter(Mandatory = $true)][string]$BlogUrl,
        [Parameter(Mandatory = $true)][int]$Offset
    )

    $Req = "https://api.tumblr.com/v2/blog/$BlogUrl/posts?api_key=$Key&npf=false&reblog_info=false&limit=40&offset=$Offset"
    $Data = Invoke-RestMethod -Method 'Get' -Uri $Req
    $Data | ConvertTo-Json -Depth 50 | Out-File "./responses/list_$RetrievedPosts.json" -Encoding UTF8

    $BlogName = $Data.response.blog.title
    $BlogUrl = $Data.response.blog.url
    $PostCount = $Data.response.posts.length
    
    Write-Host "Fetched $PostCount posts from $BlogName ($BlogUrl)"
    return $Data
}

# Check that ZIP download is present
if (-not(Test-Path "*.zip")) {
    Write-Host "Can't find Tumblr export ZIP! It should be here: $(Join-Path -Path $pwd -ChildPath 'example.zip')"
    exit
}

# Unzip Tumblr ZIP download
if (-not(Test-Path "./import/*.zip")) {
    $TumblrZip = Get-ChildItem -Path (Join-Path -Path $pwd -ChildPath '*.zip') | Select-Object -First 1
    Expand-Archive -Path $TumblrZip -DestinationPath "./import"
    Write-Host "Extracted Tumblr archive to this directory: $(Join-Path -Path $pwd -ChildPath 'import')"
}

# Unzip posts
if (-not(Test-Path "./import/posts/")) {
    Expand-Archive -Path "./import/posts.zip" -DestinationPath "./import/posts"
    Write-Host "Extracted posts from Tumblr archive to this directory: $(Join-Path -Path $pwd -ChildPath 'import/posts')"
}

# Create folder for JSON responses
$null = New-Item -ItemType Directory -Force -Path "responses"

# Copy media directory to export folder
Copy-Item -Path "./import/media" -Destination "./export/tumblr_media" -Recurse -Force
Write-Host "Copied media to export directory"

# Run search and iterate through all pages
while ($ContinueSearching -eq $true) {
    $ThisPage = Get-Tumblr-Posts -ApiKey $key -BlogUrl $blog -Offset $RetrievedPosts
    if ($ThisPage.response.posts -and $ThisPage.response.posts.items) {
        $RetrievedPosts += $ThisPage.response.posts.Length
        foreach ($Post in $ThisPage.response.posts) {
            # Create output directory
            $null = New-Item -ItemType Directory -Force -Path "export/$($Post.slug)"
            # Set output files
            $OriginalPath = Join-Path -Path $pwd -ChildPath "import/posts/html/$($Post.id).html"
            $TargetPath = Join-Path -Path $pwd -ChildPath "export/$($Post.slug)/$($Post.slug).html"
            $TargetJson = Join-Path -Path $pwd -ChildPath "export/$($Post.slug)/$($Post.slug).json"
            # Clean up HTML with Pandoc
            $Pandoc = & pandoc $OriginalPath -f html -t html --ascii=true --wrap=none
            $Html = $Pandoc | Out-String
            # Replace media paths
            $Html = $Html -replace '../../media/', '../tumblr_media/'
            # Remove "More" divider
            $Html = $Html -replace '<p>\[\[MORE\]\]</p>', ''
            # Remove "ALT" button under images
            $Html = $Html -replace '<span class="tmblr-alt-text-helper">ALT</span>', ""
            # Remove empty headers
            $Html = $Html -replace '<h1 id="section"></h1>', ''
            # Remove footers
            $Html = $Html -replace '<div id="footer"[\s\S]*?<\/div>', ''
            # Write HTML file
            $Html | Out-File -FilePath $TargetPath -Force
            # Write metadata to JSON file
            $PostMetadata = [PSCustomObject]@{
                permalink   = ($Post.post_url -replace $Post.blog.url, "") + "/index.html"
                date        = [DateTimeOffset]::FromUnixTimeSeconds($Post.timestamp).UtcDateTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
                tumblr_id   = $Post.id
                tumblr_url  = $Post.post_url
            }
            if ($Post.title) {
                $PostMetadata | Add-Member -MemberType NoteProperty -Name 'title' -Value $Post.title
            }
            else {
                $PostMetadata | Add-Member -MemberType NoteProperty -Name 'title' -Value $Post.summary
            }
            if ($tag) {
                $PostMetadata | Add-Member -MemberType NoteProperty -Name 'tags' -Value (@($tag) + $Post.tags)
            }
            else {
                $PostMetadata | Add-Member -MemberType NoteProperty -Name 'tags' -Value $Post.tags
            }
            $PostMetadata | ConvertTo-Json -Depth 1 | Set-Content -Path $TargetJson -Encoding UTF8
            # Finished
            Write-Host "Finished converting: $($PostMetadata.title) ($($Post.date))"
        }
    }
    else {
        $ContinueSearching = $false
        Write-Host "Finished search with $RetrievedPosts posts."
    }
}