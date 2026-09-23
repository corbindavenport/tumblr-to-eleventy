#Requires -Version 7.0

param (
    [Parameter(Mandatory = $true)][string]$key,
    [Parameter(Mandatory = $true)][string]$blog,
    [Parameter(Mandatory = $false)][string]$tag,
    [Parameter(Mandatory = $false)][string]$parsemedia = "false"
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

# Copy media directory to export folder, if parsemedia option is not enabled
if ([System.Convert]::ToBoolean($parsemedia) -eq $false) {
    Copy-Item -Path "./import/media" -Destination "./export/tumblr_media" -Recurse -Force
    Write-Host "Copied media to export directory"
}

# Run search and iterate through all pages
while ($ContinueSearching -eq $true) {
    $ThisPage = Get-Tumblr-Posts -ApiKey $key -BlogUrl $blog -Offset $RetrievedPosts
    if ($ThisPage.response.posts -and $ThisPage.response.posts.items) {
        $RetrievedPosts += $ThisPage.response.posts.Length
        foreach ($Post in $ThisPage.response.posts) {
            # Create output directory
            $null = New-Item -ItemType Directory -Force -Path "export/$($Post.slug)"
            # Set input and output files
            $InputMedia = Join-Path -Path $pwd -ChildPath "import/media/"
            $InputHtml = Join-Path -Path $pwd -ChildPath "import/posts/html/$($Post.id).html"
            $OutputPath = Join-Path -Path $pwd -ChildPath "export/$($Post.slug)/"
            $OutputHtml = Join-Path -Path $OutputPath -ChildPath "index.html"
            $OutputJson = Join-Path -Path $OutputPath -ChildPath "index.json"
            $Html = Get-Content -Path $InputHtml
            # Clean up HTML with Tidy
            $Html = $Html | tidy -q --show-body-only yes --wrap 0 --indent yes --show-warnings no 2>$null | Out-String
            # Move media files
            if ([System.Convert]::ToBoolean($parsemedia) -eq $true) {
                # Detect embedded media in HTML files, move them to the post's folder, and update the path in the HTML
                $Pattern = '(?:\.\./\.\./media/)(?<FileName>[^\s"]+)'
                foreach ($Match in [regex]::Matches($Html, $Pattern)) {
                    # Copy the media to the post's folder
                    $FileLocation = Join-Path -Path $InputMedia -ChildPath $Match.Groups['FileName'].Value
                    $FileDestination = Join-Path -Path $OutputPath -ChildPath $Match.Groups['FileName'].Value
                    Copy-Item -Path $FileLocation -Destination $FileDestination -Recurse -Force
                    # Replace the path in the HTML file
                    $Html = $Html -replace $Match.Value, $Match.Groups['FileName'].Value
                }
            } else {
                # Keep all media in original folder for best compatibility
                $Html = $Html -replace '../../media/', '../tumblr_media/'
            }
            # Remove summary and/or title being used as the first H1
            $Html = $Html -replace "<h1>$($Post.title)</h1>", ""
            $Html = $Html -replace "<h1>$($Post.summary)</h1>", ""
            # Remove href.li link redirects
            # Example: "https://href.li/?https://en.wikipedia.org/wiki/IMac_G3" becomes "https://en.wikipedia.org/wiki/IMac_G3"
            # Tumblr stopped adding this to posts in November 2023: https://www.tumblr.com/changes/734888841528410112
            $Html = $Html -replace 'https://href.li/\?', ''
            # Remove "More" divider
            $Html = $Html -replace '\[\[MORE\]\]', ''
            # Remove "ALT" button under images
            $Html = $Html -replace '<span class="tmblr-alt-text-helper">ALT</span>', ""
            # Remove empty headers
            $Html = $Html -replace '<h1 id="section"></h1>', ''
            # Remove footers
            $Html = $Html -replace '<div id="footer"[\s\S]*?<\/div>', ''
            # Write HTML file
            $Html.Trim() | Out-File -FilePath $OutputHtml -NoNewline -Force
            # Write metadata to JSON file
            $PostMetadata = [PSCustomObject]@{
                title            = $Post.title ? $Post.title : $Post.summary
                permalink        = ($Post.post_url -replace $Post.blog.url, "/") + "/index.html"
                date             = [DateTimeOffset]::FromUnixTimeSeconds($Post.timestamp).UtcDateTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
                tags             = $tag ? (@($tag) + $Post.tags) : $Post.tags
                tumblr_id        = $Post.id
                tumblr_url       = $Post.post_url
                tumblr_short_url = $Post.short_url
                tumblr_blog_name = $Post.blog_name
            }
            $PostMetadata | ConvertTo-Json -Depth 1 | Set-Content -Path $OutputJson -Encoding UTF8
            # Finished
            Write-Host "Finished converting: $($PostMetadata.title) ($($Post.date))"
        }
    }
    else {
        $ContinueSearching = $false
        Write-Host "Finished search with $RetrievedPosts posts."
    }
}