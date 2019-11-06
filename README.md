# webls
This project aims to be a simple and lightweight website generator and an alternative to `jekyll`, `hugo` and alike. The project is purely written in lua and will also require lua-filesystem to be installed on your system.

The goal of `webls` is, to automatically create a hierarchically ordered website, based on the file-structure of the input directory. When `webls` is executed, it will recursivly scan through the `config.content` ([config.lua](config.lua)) directory and search for all folders, images, archives and markdown files. Those will then be rendered and/or copied to the `config.www` ([config.lua](config.lua)) folder, where as a result, the website is generated.
Textfiles will be rendered via [lua-markdown](https://github.com/mpeterv/markdown.git) into html code and folders are displayed as sidebar entries. Several other modules exist and will generate additional content based on the `config.modules`([config.lua](config.lua)) you have set.

An example page can be found here: [webls-demo](https://shagu.github.io/webls) that is using the data found in [content](https://github.com/shagu/webls/tree/master/content).


## Getting Started

### GitHub (Travis)

 1. Create a new repository
 2. Create an empty `./content` folder
 3. Drop the desired files and folders into `./content`
 4. [Generate an access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) for Travis
 5. Enable [Travis-CI](https://travis-ci.org) for your new repository
 6. Open the travis repository settings, and add a new variable.

        Name: GITHUB_TOKEN
        Value: «Your token»

 7. Add and commit a [.travis.yml](.travis.yml) file to your repository:

        language: generic

        addons:
          apt:
            update: true
            packages:
              - lua5.2
              - lua-filesystem

        script:
          - git clone --recursive https://github.com/shagu/webls.git .webls
          - cp -f .webls-config.lua .webls/config.lua || true
          - rm -r .webls/content
          - cp -r content .webls/content
          - ( cd .webls && ./webls.lua )
          - mv .webls/www public

        deploy:
          provider: pages
          skip_cleanup: true
          github_token: $GITHUB_TOKEN
          local-dir: public

Travis should now start automatically and prepare your website. The page should now become available under: **https://«yourname».github.io/«repoistory»**.

### GitLab

 1. Create a new repository
 2. Create an empty `./content` folder
 3. Drop the desired files and folders into `./content`
 4. Add and commit a [.gitlab-ci.yml](.gitlab-ci.yml) file to your repository:

        pages:
          stage: deploy
          image: archlinux/base:latest
          variables:
            GIT_SUBMODULE_STRATEGY: recursive

          before_script:
            - pacman --noconfirm -Syu
            - pacman --noconfirm -S lua lua-filesystem git
            - git clone --recursive https://github.com/shagu/webls.git .webls

          script:
            - cp -f .webls-config.lua .webls/config.lua || true
            - rm -r .webls/content
            - cp -r content .webls/content
            - ( cd .webls && ./webls.lua )
            - mv .webls/www public

          artifacts:
            paths:
            - public

GitLab-CI should now start automatically and prepare your website. The page should now become available under: **https://«yourname».gitlab.io/«repoistory»**.

### Customization
To customize a webls website, add and commit a [.webls-config.lua](config.lua) file into the root directory of your website repository. The above mentioned ci-configs make sure, the config will be used.
The [Configuration File](config.lua) includes the following options:

 - **title**: The title of the website which is shown on the browser titlebar and on the website itself as header
 - **description:**: A brief description of your website, a slogan or whatever. It is displayed next to the title
 - **website:**: The full name of the domain that your website runs on. Is not yet in use
 - **cname**: The domain of your website. Will create a CNAME file in the output directory. Required for custom domains on github-pages
 - **pagesuffix**: When set to true, all generated sidebar links will point to an index.html of the directory. This is useful for local development.
 - **scanpath**: The foldername of the input directory, where the content is present.
 - **www**: The foldername of the output directory, where the content should be rendered to.
 - **modules:**: All available modules that are used to render content in the specified order.
   - **html:** all html-files found in the input directory will be added to the content view. *(.html, .htm)*
   - **markdown:** is the core module and converts text and markdown files into html. *(.md, .txt)*
   - **git**: will display a widget with the git-url and a link to the latest download.zip if github or gitlab is detected.
   - **gallery**: will add an image-gallery to the page. *(.png, .jpg, .jpeg, .webp, .gif)*
   - **download**: will add a download section to the page. *(.tar, .gz, .bz2, .xz, .zip, .rar)*
   - **footer**: adds a footer to the page.

 - **colors**: The colors that are used for the website
   - **accent**: The unique color of your website
   - **border**: The default border color around all objects, and the top-navigation background
   - **bg-page**: The background of the body of the page
   - **bg-content**: The background color of the modules generated fields
   - **bg-sidebar**: The background color of the sidebar
   - **fg-page**: The font color of the body of the page
   - **fg-sidebar**: The font color of the sidebar
