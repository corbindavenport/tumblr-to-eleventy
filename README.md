# Tumblr to Eleventy Migration Tool

A PowerShell script for migrating Tumblr blog posts to an [Eleventy website](https://www.11ty.dev/), while retaining their original permalinks, titles, tags, and other metadata. The output format for posts is HTML, not Markdown, using Tumblr's own HTML export and cleaned up with [Pandoc](https://pandoc.org).

**Note:** This was only tested with my personal blog's ~80 posts, running on macOS.

## How to use the script

You need [PowerShell 7 or later](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell) and [Pandoc](https://pandoc.org). You can install them with [Homebrew](https://brew.sh/) on macOS like this:

```shell
brew install powershell pandoc
```

You also need an [export of your Tumblr blog](https://help.tumblr.com/knowledge-base/export-your-blog/). When it's ready, download the ZIP file and place it in the directory where you are running the script.

Next, register an [API application with Tumblr](https://www.tumblr.com/oauth/apps). You can put anything in the title, callback URL, and other required fields.

Finally, run the script like this:

```shell
pwsh ./main.ps1 -key YourKeyGoesHere -blog myblog.tumblr.com -tag "post"
```

Your OAuth Consumer Key from your application's API page goes in the `key` parameter, and your blog's domain or other [valid blog identifier](https://www.tumblr.com/docs/en/api/v2#blog-identifiers) in the `blog` parameter.

The `tag` parameter is optional, but you can use it to apply a certain tag to all exported posts. For example, if you're already using a "post" tag for all your blog posts, you should add that to the command.

## How to move the posts to Eleventy

The script saves your converted posts in a `exports` directory. You can move the contents to any location in your Eleventy site's structure.

If you are using the [Eleventy Image plugin](https://www.11ty.dev/docs/plugins/image/), you may see errors about missing alt text on images. You can fix that by adding alt text to the images, or adding a default blank value to your configuration, like this:

```js
module.exports = function(eleventyConfig) {
  eleventyConfig.addPlugin(eleventyImageTransformPlugin, {
    defaultAttributes: {
      alt: ""
    },
  });
};
```

## Example output for a post

Original Tumblr post: [How I rewrote Nexus Tools with Dart](https://web.archive.org/web/20211003194200/https://blog.corbin.io/post/664051705424592896/how-i-rewrote-nexus-tools-with-dart)

### HTML for post

```html
<p>Last month, I updated a project of mine called <a href="https://href.li/?https://github.com/corbindavenport/nexus-tools">Nexus Tools</a>, which is an installer for Google&#x2019;s Android SDK Platform Tools. It&#x2019;s one of my most popular software projects, with around 1.1-1.3k users per month, and version 5.0 is a complete rewrite. The switch seemed to go fine (no bug reports yet!), so I wanted to write a blog post about the development process, in the hopes that it might help others experimenting with bash scripts or Dart programming.</p>

<h1 id="the-old-bash-script">The old bash script</h1>
<p>Before v5.0, Nexus Tools was written as a <a href="https://href.li/?https://en.wikipedia.org/wiki/Bash_(Unix_shell)">bash script</a>, which is a series of commands that runs in Bash Shell (or a Bash-compatible environment). I only supported Mac and Linux at first, but over the years I also added compatibility for Chrome OS, Bash for Windows 10, and Macs with Apple Silicon chips. The main process is the same across all platforms: Nexus Tools creates a folder in the home directory, downloads and unzips the SDK Platform Tools package from Google&#x2019;s server, and adds it to the <a href="https://href.li/?https://en.wikipedia.org/wiki/PATH_(variable)">system path</a>. Nothing too complicated.</p>
<div class="npf_row">
<figure class="tmblr-full" data-orig-height="720" data-orig-width="1280">
<img src="../tumblr_media/664051705424592896_0.png" data-orig-height="720" data-orig-width="1280" srcset="../tumblr_media/664051705424592896_0.png 75w, ../tumblr_media/664051705424592896_0.png 100w, ../tumblr_media/664051705424592896_0.png 250w, ../tumblr_media/664051705424592896_0.png 400w, ../tumblr_media/664051705424592896_0.png 500w, ../tumblr_media/664051705424592896_0.png 540w, ../tumblr_media/664051705424592896_0.png 640w, ../tumblr_media/664051705424592896_0.png 1280w" sizes="(max-width: 1280px) 100vw, 1280px" />
</figure>
</div>
// Continued...
```

### JSON for metadata

```json
{
  "title": "How I rewrote Nexus Tools with Dart",
  "permalink": "post/664051705424592896/how-i-rewrote-nexus-tools-with-dart/index.html",
  "date": "2021-10-03T19:24:16Z",
  "tags": [
    "post",
    "dart",
    "google dart",
    ...
  ],
  "tumblr_id": 664051705424592896,
  "tumblr_url": "https://blog.corbin.io/post/664051705424592896/how-i-rewrote-nexus-tools-with-dart",
  "tumblr_short_url": "https://tmblr.co/ZEbilYatBu7_Kq00",
  "tumblr_blog_name": "corbindavenport"
}
```

### File structure

```
export/how-i-rewrote-nexus-tools-with-dart/
export/how-i-rewrote-nexus-tools-with-dart/index.html
export/how-i-rewrote-nexus-tools-with-dart/index.json
export/tumblr_media/664051705424592896_0.png
[continued...]
```