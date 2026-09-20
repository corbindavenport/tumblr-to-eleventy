# Tumblr to Eleventy Migration Tool

A PowerShell script for migrating Tumblr blog posts to an [Eleventy website](https://www.11ty.dev/), while retaining their original permalinks, titles, tags, and other metadata. The output format for posts is HTML, cleaned up with [Pandoc](https://pandoc.org).

**Note:** This was only tested with my personal blog's ~80 posts, running on macOS.

### How to use the script

You need [PowerShell 7 or later](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell) and [Pandoc](https://pandoc.org). You can install them with [Homebrew](https://brew.sh/) on macOS like this:

```shell
brew install powershell pandoc
```

You also need an [export of your Tumblr blog](https://help.tumblr.com/knowledge-base/export-your-blog/). When it's ready, download the ZIP file and place it in the directory where you are running the script.

Next, register an [API application with Tumblr](https://corbin.io). You can put anything in the title, callback URL, and other required fields.

Finally, run the script like this:

```shell
pwsh ./main.ps1 -key YourKeyGoesHere -blog myblog.tumblr.com -tag "post"
```

Your OAuth Consumer Key from your application's API page goes in the `key` parameter, and your blog's domain or other [valid blog identifier](https://www.tumblr.com/docs/en/api/v2#blog-identifiers) in the `blog` parameter.

The `tag` parameter is optional, but you can use it to apply a certain tag to all exported posts. For example, if you're already using a "post" tag for all your blog posts, you should add that to the command.

### How to move the posts to Eleventy

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