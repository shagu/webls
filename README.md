# webls
This project aims to be a simple and lightweight website generator and an alternative to `jekyll`, `hugo` and alike. The project is purely written in lua and will also require lua-filesystem to be installed on your system.

The goal of `webls` is, to automatically create a hierarchically ordered website, based on the file-structure of the input directory. When `webls` is executed, it will recursivly scan through the `config.content` ([config.lua](./config.lua)) directory and search for all folders, images, archives and markdown files. Those will then be rendered and/or copied to the `config.www` ([config.lua](./config.lua)) folder, where as a result, the website is generated.
Textfiles will be rendered via [lua-markdown](https://github.com/mpeterv/markdown.git) into html code and folders are displayed as sidebar entries. Several other modules exist and will generate additional content based on the `config.modules`([config.lua](config.lua)) you have set.

An example page can be found here: [webls-demo](https://shagu.github.io/webls) that is using the data found in [content](./content).

## Modules
The `modules` table in [config.lua](config.lua) tells `webls` which modules should be used and in which order they should be displayed. Valid modules are:

- **markdown:** is the core module and converts text and markdown files into html. *(.md, .txt)*
- **git**: will display a widget with the git-url and a link to the latest download.zip if github or gitlab is detected.
- **gallery**: will add an image-gallery to the page. *(.png, .jpg, .jpeg, .webp, .gif)*
- **download**: will add a download section to the page. *(.tar, .gz, .bz2, .xz, .zip, .rar)*
- **footer**: adds a footer to the page.

## Getting Started
### GitHub (Travis)
1. Create a new repository
2. Create an empty `./content` folder
3. Drop the desired files and folders into `./content`
4. [Generate an access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) for Travis
5. Enable [Travis-CI](https://travis-ci.org) for your new repository
6. Open the travis repository settings, and add a new Environment Variable:

    Name: GITHUB_TOKEN
    Value: «Your token»

7. Add and commit a [.travis.yml](./.travis.yml) file to your repository:

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
4. Add and commit a [.gitlab-ci.yml](./.gitlab-ci.yml) file to your repository:

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
